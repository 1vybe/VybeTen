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


// Fix orientation to landscapeRight
- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIToolbar* blurredView = [[UIToolbar alloc] initWithFrame:self.view.bounds];
    NSLog(@"blurredView: %@", NSStringFromCGRect(blurredView.frame));
    [blurredView setBarStyle:UIBarStyleBlack];
    [self.view insertSubview:blurredView atIndex:0];

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

- (IBAction)goToMyTribe:(id)sender {
    VYBMyTribeViewController *myTribeVC = [[VYBMyTribeViewController alloc] init];
    [[self navigationController] pushViewController:myTribeVC animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
