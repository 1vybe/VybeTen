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

@interface VYBMenuViewController ()

@end

@implementation VYBMenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

/*
// Fix orientation to landscapeRight
- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}
*/

- (void)loadView {
    UIView *theView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view = theView;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Adding blurred screen at the bottom
    CGRect mainBounds = [[UIScreen mainScreen] bounds];
    UIToolbar* blurredView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, mainBounds.size.height, mainBounds.size.width)];
    [blurredView setBarStyle:UIBarStyleBlack];
    [self.view insertSubview:blurredView atIndex:0];

    // Adding CAPTURE button
    CGRect buttonCaptureFrame = CGRectMake(self.view.bounds.size.height - 40, self.view.bounds.size.width - 40, 34, 34);
    UIButton *buttonCapture = [[UIButton alloc] initWithFrame:buttonCaptureFrame];
    UIImage *captureImage = [UIImage imageNamed:@"button_vybe.png"];
    [buttonCapture setContentMode:UIViewContentModeScaleAspectFit];
    [buttonCapture setImage:captureImage forState:UIControlStateNormal];
    [buttonCapture addTarget:self action:@selector(captureVybe:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonCapture];
    
    // Adding MyTribe button
    CGRect buttonMyTribesFrame = CGRectMake(self.view.bounds.size.height/4 - 90, self.view.bounds.size.width/2 - 90, 180, 180);
    UIButton *buttonMyTribes = [[UIButton alloc] initWithFrame:buttonMyTribesFrame];
    UIImage *myTribesImage = [UIImage imageNamed:@"button_mytribes_circle.png"];
    [buttonMyTribes setImage:myTribesImage forState:UIControlStateNormal];
    [buttonMyTribes addTarget:self action:@selector(goToMyTribes:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonMyTribes];
    
    // Adding MyVybes button
    CGRect buttonMyVybesFrame = CGRectMake(self.view.bounds.size.height*0.75 - 90, self.view.bounds.size.width/2 - 90, 180, 180);
    UIButton *buttonMyVybes = [[UIButton alloc] initWithFrame:buttonMyVybesFrame];
    UIImage *myVybesImage = [UIImage imageNamed:@"button_myvybes_circle.png"];
    [buttonMyVybes setImage:myVybesImage forState:UIControlStateNormal];
    [buttonMyVybes addTarget:self action:@selector(goToMyVybes:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonMyVybes];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
