//
//  VYBReplayViewController.m
//  VybeTen
//
//  Created by jinsuk on 3/9/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBReplayViewController.h"
#import "VYBPlayerView.h"
#import "VYBMyVybeStore.h"

@implementation VYBReplayViewController {
    NSURL *replayURL;
}

@synthesize player = _player;
@synthesize playerItem = _playerItem;
@synthesize playerView = _playerView;
@synthesize vybe = _vybe;
@synthesize buttonDiscard, buttonSave, instruction;

- (void)loadView {
    NSLog(@"replay loadView");
    VYBPlayerView *playerView = [[VYBPlayerView alloc] init];
    self.view = playerView;
    [self.view setFrame:CGRectMake(0, 0, 320, 480)];
    self.playerView = playerView;
}
- (void)viewDidLoad
{
    NSLog(@"replay view loaded");
    [super viewDidLoad];
    // Adding swipe gestures
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(saveVybe)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    [self.view addGestureRecognizer:swipeUp];
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(discardVybe)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeDown];
    
    // First vybe instruction view
    [self.view setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
    UIImageView *instructionImg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 480, 320)];
    [instructionImg setContentMode:UIViewContentModeScaleToFill];
    [instructionImg setImage:[UIImage imageNamed:@"firstvid.png"]];
    [self.view addSubview:instructionImg];
}

- (void)saveVybe {
    // Generating and saving a thumbnail for the captured vybe
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:replayURL options:nil];
    AVAssetImageGenerator *generate = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    // To transform the snapshot to be in the orientation the video was taken with
    [generate setAppliesPreferredTrackTransform:YES];
    NSError *err = NULL;
    CMTime time = CMTimeMake(1, 60);
    CGImageRef imgRef = [generate copyCGImageAtTime:time actualTime:NULL error:&err];
    UIImage *thumb = [[UIImage alloc] initWithCGImage:imgRef];
    NSData *thumbData = UIImageJPEGRepresentation(thumb, 1);
    NSURL *thumbURL = [[NSURL alloc] initFileURLWithPath:[self.vybe thumbnailPath]];
    [thumbData writeToURL:thumbURL atomically:YES];
 
    // Save the captured vybe in MyVybeStore
    [[VYBMyVybeStore sharedStore] addVybe:self.vybe];
 
    // Upload it to AWS S3
    //NSData *videoData = [NSData dataWithContentsOfURL:replayURL];
    //[self processDelegateUpload:videoData];

    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)discardVybe {
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtURL:replayURL error:&error];
    if (error)
        NSLog(@"Removing a file failed: %@", error);
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)playVideoAtUrl:(NSURL *)url {
    replayURL = url;
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:replayURL options:nil];
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    // For play loop
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    [self setPlayer:[AVPlayer playerWithPlayerItem:self.playerItem]];
    [self.playerView setPlayer:self.player];
    [self.playerView setVideoFillMode];
    [self.player play];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self.playerItem seekToTime:kCMTimeZero];
    [self.player play];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
