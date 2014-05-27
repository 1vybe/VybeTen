//
//  VYBMainPageViewController.m
//  VybeTen
//
//  Created by jinsuk on 5/26/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBMainPageViewController.h"
#import "VYBTribesViewController.h"
#import "VYBCaptureViewController.h"
#import "VYBFriendsViewController.h"
#import "VYBWelcomeViewController.h"

@interface VYBMainPageViewController ()

@end

@implementation VYBMainPageViewController

- (id)init {
    self = [super init];
    if (self) {
        VYBTribesViewController *tribesVC = [[VYBTribesViewController alloc] init];
        VYBFriendsViewController *friendsVC = [[VYBFriendsViewController alloc] init];
        UINavigationController *navController = [[UINavigationController alloc] init];
        [[navController navigationBar] setHidden:YES];
        
        VYBCaptureViewController *captureVC = [[VYBCaptureViewController alloc] init];
        
        VYBWelcomeViewController *welcomeViewController = [[VYBWelcomeViewController alloc] init];
        
        navController.modalPresentationStyle = UIModalPresentationCurrentContext;
        
        [navController pushViewController:captureVC animated:NO];
        [navController pushViewController:welcomeViewController animated:NO];

    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationVertical options:nil];
    _pageController.delegate = self;
    _pageController.dataSource = self;
    
}

@end
