//
//  VYBTribePlayerViewController.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 10..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBTribePlayerViewController.h"
#import "VYBMyTribeStore.h"
#import "VYBPlayerView.h"

@implementation VYBTribePlayerViewController
@synthesize player = _player;
@synthesize playerView = _playerView;
@synthesize currItem = _currItem;
@synthesize labelTime, labelDate;

- (void)loadView {
    VYBPlayerView *playerView = [[VYBPlayerView alloc] init];
    self.view = playerView;
    [self.view setFrame:CGRectMake(0, 0, 320, 480)];
    self.playerView = playerView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Adding swipe gestures
    UISwipeGestureRecognizer *swipeLeft=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeLeft)];
    swipeLeft.direction=UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeLeft];
    UISwipeGestureRecognizer *swipeRight=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeRight)];
    swipeRight.direction=UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRight];
    /* NOTE: Origin for menu button is (0, 0) */
    // Adding menu button
    CGRect buttonMenuFrame = CGRectMake(0, self.view.bounds.size.width - 48, 48, 48);
    UIButton *buttonMenu = [[UIButton alloc] initWithFrame:buttonMenuFrame];
    UIImage *menuImage = [UIImage imageNamed:@"button_menu.png"];
    [buttonMenu setImage:menuImage forState:UIControlStateNormal];
    [buttonMenu addTarget:self action:@selector(goToMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonMenu];
    // Adding capture button
    CGRect buttonCaptureFrame = CGRectMake(self.view.bounds.size.height - 48, self.view.bounds.size.width - 48, 48, 48);
    UIButton *buttonCapture = [[UIButton alloc] initWithFrame:buttonCaptureFrame];
    UIImage *captureImage = [UIImage imageNamed:@"button_vybe.png"];
    [buttonCapture setImage:captureImage forState:UIControlStateNormal];
    [buttonCapture addTarget:self action:@selector(captureVybe) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonCapture];
    // Adding date label
    CGRect labelDateFrame = CGRectMake(self.view.bounds.size.height/2 - 60, 0, 120, 48);
    labelDate = [[UILabel alloc] initWithFrame:labelDateFrame];
    [labelDate setTextColor:[UIColor whiteColor]];
    [self.view addSubview:labelDate];
    // Adding time label
    CGRect labelTimeFrame = CGRectMake(self.view.bounds.size.height - 100, 0, 100, 48);
    labelTime = [[UILabel alloc] initWithFrame:labelTimeFrame];
    [labelTime setTextColor:[UIColor whiteColor]];
    [self.view addSubview:labelTime];
    
    // Start playing videos from the server
}

- (void)playFrom:(NSInteger)from {
    
}


/**
 * User Interactions
 **/

- (void)swipeLeft {
}

- (void)swipeRight {
}

- (void)captureVybe {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)goToMenu {
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
