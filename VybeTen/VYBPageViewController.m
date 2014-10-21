//
//  VYBPageViewController.m
//  VybeTen
//
//  Created by jinsuk on 6/23/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBPageViewController.h"

@interface VYBPageViewController ()

@end

@implementation VYBPageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (BOOL)prefersStatusBarHidden {
    return [self.viewControllers.firstObject prefersStatusBarHidden];
}

- (NSUInteger)supportedInterfaceOrientations {
    return [self.viewControllers.firstObject supportedInterfaceOrientations];
}

- (BOOL)shouldAutorotate {
    return [self.viewControllers.firstObject shouldAutorotate];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [self.viewControllers.firstObject preferredInterfaceOrientationForPresentation];
}


@end
