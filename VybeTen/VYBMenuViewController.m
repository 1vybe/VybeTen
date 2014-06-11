//
//  VYBMenuViewController.m
//  VybeTen
//
//  Created by jinsuk on 2/25/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBAppDelegate.h"
#import "VYBMenuViewController.h"
#import "VYBTribesViewController.h"
#import "VYBFriendsViewController.h"
#import "VYBCaptureViewController.h"

@interface VYBMenuViewController ()

@end

@implementation VYBMenuViewController {
    UIImageView *overlayView;
    VYBCaptureViewController *captureVC;
}

- (void)loadView {
    UIView *theView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view = theView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    UIDevice *iphone = [UIDevice currentDevice];
    [iphone beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIDeviceOrientationDidChangeNotification object:iphone];
    
    /*
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissMenu:)];
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.height - 150, self.view.bounds.size.width);
    UIView *tapView = [[UIView alloc] initWithFrame:frame];
    [tapView addGestureRecognizer:tapRecognizer];
    [self.view addSubview:tapView];
    */
    
    // Adding blurred dark background for menu column
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    UIToolbar *menuColumn = [[UIToolbar alloc] initWithFrame:frame];
    [menuColumn setBarStyle:UIBarStyleBlack];
    [self.view addSubview:menuColumn];
    
    // Adding TRIBES button
    frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height/3);
    UIButton *buttonMyTribes = [[UIButton alloc] initWithFrame:frame];
    [buttonMyTribes setTitle:@"T R I B E S" forState:UIControlStateNormal];
    [buttonMyTribes.titleLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20.0f]];
    [buttonMyTribes addTarget:self action:@selector(goToMyTribes:) forControlEvents:UIControlEventTouchUpInside];
    [menuColumn addSubview:buttonMyTribes];
    CALayer *bottomBorder2 = [CALayer layer];
    bottomBorder2.frame = CGRectMake(0, self.view.bounds.size.height/3, self.view.bounds.size.width, 1.0f);
    bottomBorder2.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.5f].CGColor;
    [buttonMyTribes.layer addSublayer:bottomBorder2];
    
    // Adding FRIENDS button
    frame = CGRectMake(0, self.view.bounds.size.height/3, self.view.bounds.size.width, self.view.bounds.size.height/3);
    UIButton *buttonFriends = [[UIButton alloc] initWithFrame:frame];
    [buttonFriends setTitle:@"F R I E N D S" forState:UIControlStateNormal];
    [buttonFriends.titleLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20.0f]];
    [buttonFriends addTarget:self action:@selector(goToFriends:) forControlEvents:UIControlEventTouchUpInside];
    [menuColumn addSubview:buttonFriends];
    CALayer *bottomBorder3 = [CALayer layer];
    bottomBorder3.frame = CGRectMake(0, self.view.bounds.size.height/3, self.view.bounds.size.width, 1.0f);
    bottomBorder3.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.5f].CGColor;
    [buttonFriends.layer addSublayer:bottomBorder3];
    
    // Adding MyVybes button
    frame = CGRectMake(0, self.view.bounds.size.height*2/3, self.view.bounds.size.width, self.view.bounds.size.height/3);
    UIButton *buttonMyVybes = [[UIButton alloc] initWithFrame:frame];
    [buttonMyVybes setTitle:@"M Y  V Y B E S" forState:UIControlStateNormal];
    [buttonMyVybes.titleLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20.0f]];
    [buttonMyVybes addTarget:self action:@selector(goToMyVybes:) forControlEvents:UIControlEventTouchUpInside];
    [menuColumn addSubview:buttonMyVybes];
}

- (void)deviceOrientationChanged:(NSNotification *)note {
    UIDevice *device = [note object];
    if ( UIDeviceOrientationIsPortrait([device orientation]) ) {
        /*
        if (!overlayView) {
            UIWindow *window = self.view.window;
            overlayView = [[UIImageView alloc] initWithFrame:window.bounds];
            [overlayView setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.8f]];
            [overlayView setUserInteractionEnabled:YES];
            [overlayView setContentMode:UIViewContentModeCenter];
            [overlayView setImage:[UIImage imageNamed:@"screen_warning_rotate.png"]];
            [window addSubview:overlayView];
        }
        */
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if ( UIDeviceOrientationIsLandscape([device orientation]) ) {
        /*
        [overlayView removeFromSuperview];
        overlayView = nil;
         */
        captureVC = [[VYBCaptureViewController alloc] init];
        [self presentViewController:captureVC animated:YES completion:nil];
    }
}


/**
 * Actions that are triggered by buttons
 **/

- (void)dismissMenu:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)goToMyTribes:(id)sender {
    VYBTribesViewController *tribesVC = [[VYBTribesViewController alloc] init];
    [self.navigationController pushViewController:tribesVC animated:NO];
}

- (void)goToFriends:(id)sender {
    VYBFriendsViewController *friendsVC = [[VYBFriendsViewController alloc] init];
    [self.navigationController pushViewController:friendsVC animated:NO];
}

- (void)goToMyVybes:(id)sender {
    [(VYBAppDelegate *)[[UIApplication sharedApplication] delegate] logOut];
}





@end
