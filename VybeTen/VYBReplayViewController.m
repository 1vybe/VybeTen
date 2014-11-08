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

@interface VYBReplayViewController () <UITextFieldDelegate, UIActionSheetDelegate>

@property (nonatomic, weak) IBOutlet UIButton *rejectButton;
@property (nonatomic, weak) IBOutlet UILabel *acceptLabel;
@property (nonatomic, weak) IBOutlet UILabel *zoneLabel;
@property (nonatomic, weak) IBOutlet VYBPlayerView *playerView;

- (IBAction)rejectButtonPressed:(id)sender;
- (IBAction)selectZoneButtonPressed:(id)sender;
- (IBAction)acceptButtonPressed:(id)sender;

@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerItem *currItem;

@end

@implementation VYBReplayViewController {
    VYBVybe *_currVybe;
    NSArray *_suggestions;
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
    
    Zone *currZone = [[VYBMyVybeStore sharedStore] currZone];
    if (currZone && [[VYBMyVybeStore sharedStore] suggestionsContainZone:currZone.zoneID]) {
        [self.zoneLabel setText:currZone.name];
    }
    
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
    NSArray *suggestions = [[VYBMyVybeStore sharedStore] zoneSuggestions];
    if (suggestions && suggestions.count > 0) {
        [self displayCurrentPlaceSuggestions:suggestions];
    }
}

- (void)displayCurrentPlaceSuggestions:(NSArray *)suggestions {
    CLLocationManager *tmp = [[CLLocationManager alloc] init];
    BOOL isLatestOS = [tmp respondsToSelector:@selector(requestAlwaysAuthorization)];
    
    // iOS 8
    if (isLatestOS) {
        UIAlertController *checkInController = [UIAlertController alertControllerWithTitle:@"Check-in" message:@"Where are you vybing? :)" preferredStyle:UIAlertControllerStyleActionSheet];
        for (Zone *aZone in suggestions) {
            UIAlertAction *action = [UIAlertAction actionWithTitle:aZone.name style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [[VYBMyVybeStore sharedStore] setCurrZone:aZone];
                [self.zoneLabel setText:aZone.name];
            }];
            [checkInController addAction:action];
        }
        if (checkInController.actions.count > 0) {
            Zone *currZone = [[VYBMyVybeStore sharedStore] currZone];
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
    else {
        UIActionSheet *actionsheet = [[UIActionSheet alloc] initWithTitle:@"Where are you vybing?" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        for (Zone *aZone in _suggestions) {
            [actionsheet addButtonWithTitle:aZone.name];
        }
        [actionsheet addButtonWithTitle:@"Go Back"];
        actionsheet.cancelButtonIndex = _suggestions.count;
        dispatch_async(dispatch_get_main_queue(), ^{
            [actionsheet showInView:[UIApplication sharedApplication].keyWindow];
        });
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    // cancel button 
    if (buttonIndex == _suggestions.count) {

    }
    else {
        Zone *zone = _suggestions[buttonIndex];
        [self.zoneLabel setText:zone.name];
        [[VYBMyVybeStore sharedStore] setCurrZone:zone];
    }
}


- (IBAction)acceptButtonPressed:(id)sender {
    Zone *currZone = [[VYBMyVybeStore sharedStore] currZone];
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


#pragma mark - DeviceOrientation

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    VYBVybe *currVybe = [[VYBMyVybeStore sharedStore] currVybe];
    NSURL *videoURL = [[NSURL alloc] initFileURLWithPath:[currVybe videoFilePath]];
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
