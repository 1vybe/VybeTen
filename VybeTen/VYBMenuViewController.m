//
//  VYBMenuViewController.m
//  VybeTen
//
//  Created by jinsuk on 2/25/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBMenuViewController.h"
#import "VYBMyVybesViewController.h"
#import "VYBMyTribeViewController.h"
#import "VYBAnimator.h"
@interface VYBMenuViewController ()

@property (strong, nonatomic) VYBAnimator *animator;
@property (strong, nonatomic) UIPercentDrivenInteractiveTransition* interactionController;

@end

@implementation VYBMenuViewController


- (void)loadView {
    UIView *theView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view = theView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Adding blurred dark background for menu column
    CGRect menuBounds = CGRectMake(self.view.bounds.size.height - 150, 0, 150, self.view.bounds.size.width);
    UIToolbar *menuColumn = [[UIToolbar alloc] initWithFrame:menuBounds];
    [menuColumn setBarStyle:UIBarStyleBlack];
    //[menuColumn setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.5f]];
    [self.view addSubview:menuColumn];
    
    // Adding CAPTURE button
    CGRect buttonCaptureFrame = CGRectMake(self.view.bounds.size.height - 50, self.view.bounds.size.width - 50, 50, 50);
    UIButton *buttonCapture = [[UIButton alloc] initWithFrame:buttonCaptureFrame];
    UIImage *captureImage = [UIImage imageNamed:@"button_vybe.png"];
    [buttonCapture setContentMode:UIViewContentModeCenter];
    [buttonCapture setImage:captureImage forState:UIControlStateNormal];
    [buttonCapture addTarget:self action:@selector(captureVybe:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonCapture];
    


    // Adding Explore button
    CGRect buttonExploreFrame = CGRectMake(0, 0, 150, 100);
    UIButton *buttonExplore = [[UIButton alloc] initWithFrame:buttonExploreFrame];
    [buttonExplore setTitle:@"E X P L O R E" forState:UIControlStateNormal];
    [buttonExplore.titleLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20.0f]];
    [buttonExplore addTarget:self action:@selector(goToMyVybes:) forControlEvents:UIControlEventTouchUpInside];
    [menuColumn addSubview:buttonExplore];
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(20, 100, 110, 1.0f);
    bottomBorder.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.5f].CGColor;
    [buttonExplore.layer addSublayer:bottomBorder];
    
    // Adding MyTribe button
    CGRect buttonMyTribesFrame = CGRectMake(0, 100, 150, 100);
    UIButton *buttonMyTribes = [[UIButton alloc] initWithFrame:buttonMyTribesFrame];
    [buttonMyTribes setTitle:@"T R I B E S" forState:UIControlStateNormal];
    [buttonMyTribes.titleLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20.0f]];
    [buttonMyTribes addTarget:self action:@selector(goToMyTribes:) forControlEvents:UIControlEventTouchUpInside];
    [menuColumn addSubview:buttonMyTribes];
    CALayer *bottomBorder2 = [CALayer layer];
    bottomBorder2.frame = CGRectMake(20, 100, 110, 1.0f);
    bottomBorder2.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.5f].CGColor;
    [buttonMyTribes.layer addSublayer:bottomBorder2];
    
    // Adding MyVybes button
    CGRect buttonMyVybesFrame = CGRectMake(0, 200, 150, 100);
    UIButton *buttonMyVybes = [[UIButton alloc] initWithFrame:buttonMyVybesFrame];
    [buttonMyVybes setTitle:@"M Y  V Y B E S" forState:UIControlStateNormal];
    [buttonMyVybes.titleLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20.0f]];
    [buttonMyVybes addTarget:self action:@selector(goToMyVybes:) forControlEvents:UIControlEventTouchUpInside];
    [menuColumn addSubview:buttonMyVybes];
}

/**
 * Actions that are triggered by buttons
 **/

- (void)captureVybe:(id)sender {
    [[self navigationController] popViewControllerAnimated:NO];
}

- (void)goToMyVybes:(id)sender {
    VYBMyVybesViewController *myVybesVC = [[VYBMyVybesViewController alloc] init];
    [[self navigationController] pushViewController:myVybesVC animated:NO];
}

- (void)goToMyTribes:(id)sender {
    VYBMyTribeViewController *myTribeVC = [[VYBMyTribeViewController alloc] init];
    [[self navigationController] pushViewController:myTribeVC animated:NO];
}


@end
