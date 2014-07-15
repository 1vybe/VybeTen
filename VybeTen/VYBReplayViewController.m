//
//  VYBReplayViewController.m
//  VybeTen
//
//  Created by jinsuk on 7/11/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBReplayViewController.h"
#import "VYBPlayerView.h"
#import "VYBUtility.h"
#import "VYBMyVybeStore.h"

@interface VYBReplayViewController ()

@end

@implementation VYBReplayViewController

- (void)dealloc {
    self.player = nil;
    self.playerView = nil;
}

- (void)loadView {
    UIView *darkBackground = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [darkBackground setBackgroundColor:[UIColor blackColor]];
    self.view = darkBackground;
    
    
    VYBPlayerView *playerView = [[VYBPlayerView alloc] init];
    
    [playerView setFrame:CGRectMake(0, 0, darkBackground.bounds.size.height, darkBackground.bounds.size.width)];
    
    self.playerView = playerView;
    
    self.player = [[AVPlayer alloc] init];
    
    [self.playerView setPlayer:self.player];
    
    [self.view addSubview:self.playerView];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Hide status bar
    [self setNeedsStatusBarAppearanceUpdate];
   
    // Adding CONFIRM button
    CGRect frame = CGRectMake(self.view.bounds.size.height - 70, 0, 70, 70);
    self.confirmButton = [[UIButton alloc] initWithFrame:frame];
    [self.confirmButton setImage:[UIImage imageNamed:@"button_replay_confirm.png"] forState:UIControlStateNormal];
    [self.confirmButton addTarget:self action:@selector(confirmButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.confirmButton];
    
    frame = CGRectMake(self.view.bounds.size.height - 70, self.view.bounds.size.width - 70, 70, 70);
    self.cancelButton = [[UIButton alloc] initWithFrame:frame];
    [self.cancelButton setImage:[UIImage imageNamed:@"button_replay_cancel.png"] forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.cancelButton];

    NSURL *videoURL = [[NSURL alloc] initFileURLWithPath:[self.currVybe videoFilePath]];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    self.currItem = [AVPlayerItem playerItemWithAsset:asset];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
    [self.player replaceCurrentItemWithPlayerItem:self.currItem];
    [self.player play];
}

- (void)playerItemDidReachEnd {
    [self.currItem seekToTime:kCMTimeZero];
    [self.player play];
}

- (void)confirmButtonPressed:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Saves a thumbmnail to local
        [VYBUtility saveThumbnailImageForVybeWithFilePath:self.currVybe.uniqueFileName];
    });
    
    [[VYBMyVybeStore sharedStore] uploadVybe:self.currVybe];
    
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)cancelButtonPressed:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:[self.currVybe videoFilePath]];
        
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtURL:outputURL error:&error];
        if (error) {
            NSLog(@"Cached my vybe was NOT deleted");
        }
    });
    
    [self.navigationController popViewControllerAnimated:NO];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}


@end
