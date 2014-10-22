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
#import "VYBNavigationController.h"
#import "AVAsset+VideoOrientation.h"

@interface VYBReplayViewController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIView *acceptButton;
@property (nonatomic, weak) IBOutlet UIButton *rejectButton;
@property (nonatomic, weak) IBOutlet UITextField *tagTextField;
@property (nonatomic, weak) IBOutlet VYBPlayerView *playerView;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *acceptButtonBottomSpacingConstraint;

- (IBAction)rejectButtonPressed:(id)sender;

@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerItem *currItem;

@end

@implementation VYBReplayViewController

- (void)dealloc {
    self.player = nil;
    self.playerView = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBMyVybeStoreLocationFetchedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.player = [[AVPlayer alloc] init];
    
    [self.playerView setPlayer:self.player];
    
    _currVybe = [[VYBMyVybeStore sharedStore] currVybe];
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationFetched:) name:VYBMyVybeStoreLocationFetchedNotification object:nil];
    
    // Register for keyboard notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    UIFont *theFont = [UIFont fontWithName:@"Helvetica Neue" size:15.0];
    NSDictionary *stringAttributes = @{ NSForegroundColorAttributeName : [UIColor colorWithRed:72.0/255.0 green:72.0/255.0 blue:72.0/255.0 alpha:1.0],
                                        NSFontAttributeName : theFont};
    self.tagTextField.delegate = self;
    self.tagTextField.clearsOnBeginEditing = YES;
    self.tagTextField.clearsOnInsertion = NO;
    self.tagTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:([_currVybe tagString])? [_currVybe tagString] : @"tag your vybe :)" attributes:stringAttributes];
    self.tagTextField.leftViewMode = UITextFieldViewModeAlways;
    [self.tagTextField setLeftView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 15.0, 15.0)]];
    
    UITapGestureRecognizer *tapToAccep = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(acceptButtonPressed)];
    tapToAccep.numberOfTapsRequired = 1;
    [self.acceptButton addGestureRecognizer:tapToAccep];
    
    UITapGestureRecognizer *tapToDismissKeyboard = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTouchedToDismissKeyboard)];
    tapToDismissKeyboard.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapToDismissKeyboard];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
  
    NSURL *videoURL = [[NSURL alloc] initFileURLWithPath:[self.currVybe videoFilePath]];
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

- (void)acceptButtonPressed {
    if (self.tagTextField.text && (self.tagTextField.text.length > 0)) {
        if (self.tagTextField.text.length < 3) {
            self.tagTextField.text = @"";
            return;
        }
        
        [[[VYBMyVybeStore sharedStore] currVybe] setTag:self.tagTextField.text];
    }
    
    [[VYBMyVybeStore sharedStore] uploadCurrentVybe];
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}


- (IBAction)rejectButtonPressed:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:[self.currVybe videoFilePath]];
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
    [self.acceptButton setNeedsUpdateConstraints];
    [UIView animateWithDuration:animationDuration animations:^{
        [self.acceptButton layoutIfNeeded];
    }];
    
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *dictionary = [notification userInfo];
    
    NSNumber *duration = [dictionary objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration = [duration doubleValue];
    
    self.acceptButtonBottomSpacingConstraint.constant = 0;
    [self.acceptButton setNeedsUpdateConstraints];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:animationDuration animations:^{
            [self.acceptButton layoutIfNeeded];
        }];
    });
}

- (void)viewTouchedToDismissKeyboard {
    [self.tagTextField resignFirstResponder];
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
    NSURL *videoURL = [[NSURL alloc] initFileURLWithPath:[self.currVybe videoFilePath]];
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
