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
@property (nonatomic) BOOL isPublic;

@end

@implementation VYBReplayViewController

- (void)dealloc {
    self.player = nil;
    self.playerView = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.player = [[AVPlayer alloc] init];
    
    [self.playerView setPlayer:self.player];
    
    // Hide status bar
    [self setNeedsStatusBarAppearanceUpdate];
   
    self.isPublic = YES;
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
    
    
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}


- (IBAction)rejectButtonPressed:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:[self.currVybe videoFilePath]];
        
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtURL:outputURL error:&error];
        if (error) {
            NSLog(@"Failed to delete the cancelled vybe.");
        }
    });
    
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - DeviceOrientation

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}


@end
