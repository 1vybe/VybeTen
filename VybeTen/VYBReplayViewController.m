//
//  VYBReplayViewController.m
//  VybeTen
//
//  Created by jinsuk on 7/11/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBAppDelegate.h"
#import "VYBReplayViewController.h"
#import "VYBPlayerView.h"
#import "MBProgressHUD.h"
#import "VYBUtility.h"
#import "VYBMyVybeStore.h"
#import "VYBOldZoneFinder.h"
#import "VYBNavigationController.h"
#import "AVAsset+VideoOrientation.h"

@interface VYBReplayViewController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIView *acceptButton;
@property (nonatomic, weak) IBOutlet UIButton *rejectButton;
@property (nonatomic, weak) IBOutlet UIButton *selectZoneButton;

@property (nonatomic, weak) IBOutlet VYBPlayerView *playerView;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *acceptButtonBottomSpacingConstraint;

- (IBAction)rejectButtonPressed:(id)sender;
- (IBAction)selectZoneButtonPressed:(id)sender;

@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerItem *currItem;

@end

@implementation VYBReplayViewController {
    VYBVybe *_currVybe;
}

- (void)dealloc {
    self.player = nil;
    self.playerView = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBMyVybeStoreLocationFetchedNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.player = [[AVPlayer alloc] init];
    
    [self.playerView setPlayer:self.player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationFetched:) name:VYBMyVybeStoreLocationFetchedNotification object:nil];
    
    VYBZone *currZone = [[VYBMyVybeStore sharedStore] currZone];
    if (currZone) {
        [self.selectZoneButton setTitle:currZone.name forState:UIControlStateNormal];
    } else {
        [self.selectZoneButton setTitle:@"Where are you vybing?" forState:UIControlStateNormal];
    }
    
    UITapGestureRecognizer *tapToAccep = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(acceptButtonPressed)];
    tapToAccep.numberOfTapsRequired = 1;
    [self.acceptButton addGestureRecognizer:tapToAccep];
    
    _currVybe = [[VYBMyVybeStore sharedStore] currVybe];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
  
    NSURL *videoURL = [[NSURL alloc] initFileURLWithPath:[_currVybe videoFilePath]];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    
    self.currItem = [AVPlayerItem playerItemWithAsset:asset];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
    [self.player replaceCurrentItemWithPlayerItem:self.currItem];
    [self.player play];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.player pause];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
}

- (void)playerItemDidReachEnd {
    [self.currItem seekToTime:kCMTimeZero];
    [self.player play];
}

#pragma mark - Zone
- (IBAction)selectZoneButtonPressed:(id)sender {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
        if (!error) {
            VYBOldZoneFinder *oldZoneFinder = [[VYBOldZoneFinder alloc] init];
            //TODO: _oldZoneFinder.numOfResults = 10;
            [oldZoneFinder findZoneNearLocationInBackgroundWithLatitude:geoPoint.latitude longitude:geoPoint.longitude completionHandler:^(NSArray *results, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                });
                if (!error) {
                    [self displayCurrentZoneSuggestions:results];
                }
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            });
        }
    }];
}

- (void)displayCurrentZoneSuggestions:(NSArray *)suggestions {
    UIAlertController *checkInController = [UIAlertController alertControllerWithTitle:@"Check-in" message:@"Where are you vybing? :)" preferredStyle:UIAlertControllerStyleActionSheet];
    for (VYBZone *aZone in suggestions) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:aZone.name style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[VYBMyVybeStore sharedStore] setCurrZone:aZone];
            [self.selectZoneButton setTitle:aZone.name forState:UIControlStateNormal];
        }];
        [checkInController addAction:action];
    }
    if (checkInController.actions.count > 0) {
        VYBZone *currZone = [[VYBMyVybeStore sharedStore] currZone];
        if (currZone) {
            [checkInController setMessage:[NSString stringWithFormat:@"Your are in %@", currZone.name]];
        }
        
    } else {
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Unlock your zone" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            // choose a name/tag for zone.
        }];
        [checkInController addAction:action];
    }
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"Go Back" style:UIAlertActionStyleCancel handler:nil];
    [checkInController addAction:action];
    
    [self presentViewController:checkInController animated:YES completion:nil];
}


- (void)acceptButtonPressed {
    VYBZone *currZone = [[VYBMyVybeStore sharedStore] currZone];
    if (currZone) {
        [[VYBMyVybeStore sharedStore] uploadCurrentVybe];
        [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    }
    else {
        //TODO: highlight zone button so they know what to do
        
    }
}


- (IBAction)rejectButtonPressed:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:[_currVybe videoFilePath]];
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtURL:outputURL error:&error];
        if (error) {
            NSLog(@"Failed to delete the cancelled vybe.");
        }
    });
    
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (void)locationFetched:(NSNotification *)notification {
    //[self.acceptButton setEnabled:YES];
}

#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *dictionary = [notification userInfo];
    CGSize keyboardSize = [[dictionary objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    
    NSNumber *duration = [dictionary objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration = [duration doubleValue];

    self.acceptButtonBottomSpacingConstraint.constant = keyboardSize.height - self.acceptButton.bounds.size.height;

    [self.view setNeedsUpdateConstraints];
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *dictionary = [notification userInfo];
    
    NSNumber *duration = [dictionary objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration = [duration doubleValue];
    
    self.acceptButtonBottomSpacingConstraint.constant = 0;
    
    [self.view setNeedsUpdateConstraints];
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.text.length < 3) {
        if (textField.text.length > 0) {
            textField.text = @"";
            return NO;
        }
    }
    
    [textField resignFirstResponder];
    [self acceptButtonPressed];
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    textField.returnKeyType = UIReturnKeyGo;
}



#pragma mark - DeviceOrientation

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    NSURL *videoURL = [[NSURL alloc] initFileURLWithPath:[_currVybe videoFilePath]];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];

    switch (asset.videoOrientation) {
        case AVCaptureVideoOrientationPortrait:
            return UIInterfaceOrientationMaskPortrait;
            break;
        case AVCaptureVideoOrientationPortraitUpsideDown:
            return UIInterfaceOrientationMaskPortraitUpsideDown;
            break;
        case AVCaptureVideoOrientationLandscapeRight:
            return UIInterfaceOrientationMaskLandscapeRight;
            break;
        case AVCaptureVideoOrientationLandscapeLeft:
            return UIInterfaceOrientationMaskLandscapeLeft;
            break;
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
