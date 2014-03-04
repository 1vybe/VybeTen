//
//  VYBPlayerViewController.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 3..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "VYBPlayerViewController.h"
#import "VYBVybeStore.h"

@interface VYBPlayerViewController ()

@end

@implementation VYBPlayerViewController {
    AVQueuePlayer *queuePlayer;
    NSInteger playIndex;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Adding swipe gestures
    UISwipeGestureRecognizer * swipeleft=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeLeft)];
    swipeleft.direction=UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeleft];
    UISwipeGestureRecognizer * swiperight=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeRight)];
    swiperight.direction=UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swiperight];

    // Add AVPlayerLayer on the view
    AVPlayerLayer *playLayer = [AVPlayerLayer playerLayerWithPlayer:queuePlayer];
    CALayer *rootLayer = [[self view] layer];
    [rootLayer setMasksToBounds:YES];
    [playLayer setFrame:rootLayer.bounds];
    [playLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [rootLayer addSublayer:playLayer];

    // Start the player
    [queuePlayer play];
}

- (void)playFromIndex:(NSInteger)index {
    playIndex = index;
    NSMutableArray *items = [[NSMutableArray alloc] init];
    for (NSInteger i = playIndex; i < [[[VYBVybeStore sharedStore] myVybes] count]; i++) {
        VYBVybe *v = [[[VYBVybeStore sharedStore] myVybes] objectAtIndex:i];
        NSURL *vybeURL = [[NSURL alloc] initFileURLWithPath:[v getVideoPath]];
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:vybeURL options:nil];
        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
        [items addObject:item];
    }
    queuePlayer = [[AVQueuePlayer alloc] initWithItems:items];
}

- (void)swipeLeft {
    playIndex++;
    [queuePlayer advanceToNextItem];
}

- (void)swipeRight {
    
    NSLog(@"swiped left");
}

- (IBAction)captureVybe:(id)sender {
    [self dismissViewControllerAnimated:NO completion:^{
        [[[self presentingViewController] navigationController] popToRootViewControllerAnimated:NO];
    }];
}

- (IBAction)goToMenu:(id)sender {
    [queuePlayer pause];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    NSLog(@"PlayViewController DESTROYED");
}


@end
