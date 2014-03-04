//
//  VYBMenuViewController.m
//  VybeTen
//
//  Created by jinsuk on 2/25/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBMenuViewController.h"
#import "VYBMyVybesViewController.h"

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


// Fix orientation to landscapeRight
- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

/**
 * Actions that are triggered by buttons
 **/

- (IBAction)captureVybe:(id)sender {
    [[self navigationController] popViewControllerAnimated:NO];
}

- (IBAction)goToMyVybes:(id)sender {
    VYBMyVybesViewController *myVybesVC = [[VYBMyVybesViewController alloc] init];
    [[self navigationController] pushViewController:myVybesVC animated:NO];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
