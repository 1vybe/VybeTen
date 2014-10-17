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

@interface VYBReplayViewController ()
@property (nonatomic, weak) IBOutlet UIButton *acceptButton;
@property (nonatomic, weak) IBOutlet UIButton *rejectButton;
@property (nonatomic, weak) IBOutlet VYBPlayerView *playerView;

- (IBAction)acceptButtonPressed:(id)sender;
- (IBAction)rejectButtonPressed:(id)sender;

@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerItem *currItem;

@end

@implementation VYBReplayViewController

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
    
    _currVybe = [[VYBMyVybeStore sharedStore] currVybe];
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationFetched:) name:VYBMyVybeStoreLocationFetchedNotification object:nil];
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

- (IBAction)acceptButtonPressed:(id)sender {
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
