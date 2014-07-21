//
//  VYBReplayViewController.m
//  VybeTen
//
//  Created by jinsuk on 7/11/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBReplayViewController.h"
#import "VYBPlayerView.h"
#import "MBProgressHUD.h"
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
    CGRect frame = CGRectMake(0, 0, 70, 70);
    self.confirmButton = [[UIButton alloc] initWithFrame:frame];
    [self.confirmButton setImage:[UIImage imageNamed:@"button_replay_confirm.png"] forState:UIControlStateNormal];
    [self.confirmButton addTarget:self action:@selector(confirmButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.confirmButton];
    
    frame = CGRectMake(0, self.view.bounds.size.width - 70, 70, 70);
    self.cancelButton = [[UIButton alloc] initWithFrame:frame];
    [self.cancelButton setImage:[UIImage imageNamed:@"button_replay_cancel.png"] forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.cancelButton];
    
    // Adding toggle switch for private/public
    frame = CGRectMake(self.view.bounds.size.height - 70, 0, 70, 70);
    self.modeToggleButton = [[UIButton alloc] initWithFrame:frame];
    [self.modeToggleButton addTarget:self action:@selector(modeToggleButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.modeToggleButton.titleLabel setFont:[UIFont fontWithName:@"AvenirLTStd-Book" size:18.0]];
    [self.modeToggleButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self.modeToggleButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.modeToggleButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [self.modeToggleButton setTitle:@"Private" forState:UIControlStateNormal];
    [self.modeToggleButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.modeToggleButton setTitle:@"Public" forState:UIControlStateSelected];
    [self.modeToggleButton setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
    [self.modeToggleButton setSelected:self.currVybe.isPublic];
    [self.view addSubview:self.modeToggleButton];

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
    NSData *video = [NSData dataWithContentsOfFile:[self.currVybe videoFilePath]];
    
    PFFile *videoFile = [PFFile fileWithData:video];
    
    PFObject *vybe = [self.currVybe parseObjectVybe];
    
    PFACL *vybeACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [vybeACL setPublicReadAccess:YES];
    vybe.ACL = vybeACL;
    
    UIProgressView *uploadProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    [uploadProgressView setFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50)];
    [self.navigationController.view addSubview:uploadProgressView];
    [videoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [vybe setObject:videoFile forKey:kVYBVybeVideoKey];
            [vybe saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    uploadProgressView.progress = 1.0;
                    [VYBUtility clearLocalCacheForVybe:self.currVybe];
                }
                else {
                    [vybe saveEventually:^(BOOL succeeded, NSError *error) {
                        [VYBUtility clearLocalCacheForVybe:self.currVybe];
                    }];
                }
                [uploadProgressView removeFromSuperview];
            }];
        } else {
            [[VYBMyVybeStore sharedStore] addVybe:self.currVybe];
            [uploadProgressView removeFromSuperview];
        }
    } progressBlock:^(int percentDone) {
        uploadProgressView.progress = (percentDone <= 90) ? percentDone / 100.0 : 0.9;
    }];
    
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)cancelButtonPressed:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:[self.currVybe videoFilePath]];
        
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtURL:outputURL error:&error];
        if (error) {
            NSLog(@"Failed to delete the cancelled vybe.");
        }
    });
    
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)modeToggleButtonPressed:(id)sender {
    self.currVybe.isPublic = !self.currVybe.isPublic;
    [self.modeToggleButton setSelected:self.currVybe.isPublic];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}


@end
