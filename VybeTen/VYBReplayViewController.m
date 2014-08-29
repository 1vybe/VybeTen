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

    [playerView setFrame:CGRectMake(0, 0, darkBackground.bounds.size.width, darkBackground.bounds.size.height)];
    
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
    CGRect frame = CGRectMake(self.view.bounds.size.width - 70, self.view.bounds.size.height - 70, 70, 70);

    self.acceptButton = [[UIButton alloc] initWithFrame:frame];
    [self.acceptButton setImage:[UIImage imageNamed:@"button_replay_accept.png"] forState:UIControlStateNormal];
    [self.acceptButton addTarget:self action:@selector(acceptButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.acceptButton];
    
    frame = CGRectMake(0, self.view.bounds.size.height - 70, 70, 70);
    self.rejectButton = [[UIButton alloc] initWithFrame:frame];
    [self.rejectButton setImage:[UIImage imageNamed:@"button_replay_reject.png"] forState:UIControlStateNormal];
    [self.rejectButton addTarget:self action:@selector(rejectButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.rejectButton];
    
    // Adding toggle switch for private/public
    frame = CGRectMake(self.view.bounds.size.height - 150, self.view.bounds.size.width - 60, 130, 40);
    self.modeControl = [[UISegmentedControl alloc] initWithItems:@[@"Public", @"Private"]];
    [self.modeControl setFrame:frame];
    [self.modeControl addTarget:self action:@selector(modeChanged:) forControlEvents:UIControlEventValueChanged];
    // By default it's public
    self.isPublic = YES;
    //[self.view addSubview:self.modeControl];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.modeControl setSelectedSegmentIndex:(self.isPublic) ? 0 : 1];
    [self.modeControl setTintColor:(self.isPublic) ? [UIColor colorWithRed:0.0 green:191.0/255.0 blue:1.0 alpha:1.0] : [UIColor orangeColor]];
    
    NSURL *videoURL = [[NSURL alloc] initFileURLWithPath:[self.currVybe videoFilePath]];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];

    NSLog(@"[REPLAY] orientation is %d", (int)[asset videoOrientation]);
    [self rotateUIElementsForOrientation:(NSInteger)[asset videoOrientation]];
    
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

- (void)rotateUIElementsForOrientation:(VYBVideoOrientation)orientation {
    CGAffineTransform transform;
    switch (orientation) {
        case VYBVideoOrientationUp:
            transform = CGAffineTransformMakeRotation(0);
            break;
        case VYBVideoOrientationDown:
            transform = CGAffineTransformMakeRotation(M_PI);
            break;
        case VYBVideoOrientationLeft:
            transform = CGAffineTransformMakeRotation(M_PI_2);
            break;
        case VYBVideoOrientationRight:
            transform = CGAffineTransformMakeRotation(-M_PI_2);
            break;
        case VYBVideoOrientationNotFound:
            transform = CGAffineTransformMakeRotation(0);

    }
    
    self.acceptButton.transform = transform;
    self.rejectButton.transform = transform;
}

- (void)playerItemDidReachEnd {
    [self.currItem seekToTime:kCMTimeZero];
    [self.player play];
}

- (void)acceptButtonPressed:(id)sender {
    NSData *video = [NSData dataWithContentsOfFile:[self.currVybe videoFilePath]];
    
    [VYBUtility saveThumbnailImageForVybe:self.currVybe];
    NSData *thumbnail = [NSData dataWithContentsOfFile:[self.currVybe thumbnailFilePath]];
    
    PFFile *videoFile = [PFFile fileWithData:video];
    PFFile *thumbnailFile = [PFFile fileWithData:thumbnail];
    
    //NOTE: vybes are ALWAYS public now
    [self.currVybe setIsPublic:YES];
    PFObject *vybe = [self.currVybe parseObjectVybe];
    
    PFACL *vybeACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [vybeACL setPublicReadAccess:YES];
    vybe.ACL = vybeACL;
    
    
    if ( [(VYBAppDelegate *)[UIApplication sharedApplication].delegate isParseReachable] ) {
        UIProgressView *uploadProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        [uploadProgressView setFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50)];
        [self.navigationController.view addSubview:uploadProgressView];
        
        [thumbnailFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                [videoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        [vybe setObject:videoFile forKey:kVYBVybeVideoKey];
                        [vybe setObject:thumbnailFile forKey:kVYBVybeThumbnailKey];
                        [VYBUtility clearLocalCacheForVybe:self.currVybe];
                        [vybe saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            if (succeeded) {
                                NSLog(@"Posted");
                                [VYBUtility showToastWithImage:[UIImage imageNamed:@"button_check.png"] title:@"Posted"];
                            }
                            else {
                                NSLog(@"Saved");
                                [vybe saveEventually];
                                [VYBUtility showToastWithImage:[UIImage imageNamed:@"button_check.png"] title:@"Saved"];
                            }
                            [uploadProgressView removeFromSuperview];
                        }];
                    } else {
                        [[VYBMyVybeStore sharedStore] addVybe:self.currVybe];
                        [uploadProgressView removeFromSuperview];
                        
                        NSLog(@"Saved");
                        [VYBUtility showToastWithImage:[UIImage imageNamed:@"button_check.png"] title:@"Saved"];
                    }
                } progressBlock:^(int percentDone) {
                    uploadProgressView.progress = percentDone / 100.0;
                }];
            } else {
                [[VYBMyVybeStore sharedStore] addVybe:self.currVybe];
                [uploadProgressView removeFromSuperview];
                
                NSLog(@"Saved");
                [VYBUtility showToastWithImage:[UIImage imageNamed:@"button_check.png"] title:@"Saved"];
            }
        }];
    } else {
        [[VYBMyVybeStore sharedStore] addVybe:self.currVybe];
    }
    
    // Update user lastVybeLocation and lastVybeTime field. lastVybeLocation is updated in captureVC didUpdateLocaton
    [[PFUser currentUser] setObject:self.currVybe.timeStamp forKey:kVYBUserLastVybedTimeKey];
    [[PFUser currentUser] saveInBackground];
    
    
    [self.navigationController popViewControllerAnimated:NO];
}


- (void)rejectButtonPressed:(id)sender {
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

- (void)modeChanged:(id)sender {
    self.isPublic = (self.modeControl.selectedSegmentIndex == 0);
    self.modeControl.tintColor = (self.isPublic) ? [UIColor colorWithRed:0.0 green:191.0/255.0 blue:1.0 alpha:1.0] : [UIColor orangeColor];
    if (self.isPublic) {
        NSLog(@"changed to public");
    }
}

#pragma mark - DeviceOrientation

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


- (BOOL)prefersStatusBarHidden {
    return YES;
}


@end
