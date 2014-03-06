//
//  VYBPlayerViewController.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 3..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBPlayerViewController.h"
#import "VYBVybeStore.h"


@implementation VYBPlayerViewController {
    NSInteger playIndex;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

#pragma mark - View Lifecycle

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
    AVPlayerLayer *playLayer = [AVPlayerLayer playerLayerWithPlayer:[self player]];
    CALayer *rootLayer = [[self view] layer];
    [rootLayer setMasksToBounds:YES];
    [playLayer setFrame:rootLayer.bounds];
    [playLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [rootLayer addSublayer:playLayer];
    
    [[self player] play];
}

- (void)playFromIndex:(NSInteger)index {
    playIndex = index;
    for (NSInteger i = index; i < [[[VYBVybeStore sharedStore] myVybes] count]; i++) {
        VYBVybe *v = [[[VYBVybeStore sharedStore] myVybes] objectAtIndex:i];
        NSURL *vybeURL = [[NSURL alloc] initFileURLWithPath:[v getVideoPath]];
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:vybeURL options:nil];
        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
        if ( [[self player] canInsertItem:item afterItem:nil] ) {
            [[self player] insertItem:item afterItem:nil];
        } else {
            NSLog(@"asset(%@) could not be added to the queue", [asset URL]);
        }
    }

}

/**
 * User Interactions
 **/
- (void)swipeLeft {
    [[self player] pause];
    [[self player] advanceToNextItem];
    [[self player] play];
}

- (void)swipeRight {
    [[self player] pause];
}

- (IBAction)captureVybe:(id)sender {
    [self dismissViewControllerAnimated:NO completion:^{
        [[[self presentingViewController] navigationController] popToRootViewControllerAnimated:NO];
    }];
}

- (IBAction)goToMenu:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
