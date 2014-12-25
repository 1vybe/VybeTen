//
//  VYBWelcomeViewController.m
//  VybeTen
//
//  Created by Mohammed Tangestani on 2014-10-08.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBWelcomeViewController.h"
#import "VYBAppDelegate.h"
#import "VYBUtility.h"
#import "VYBCache.h"

#import "VybeTen-Swift.h"

@implementation VYBWelcomeViewController

#pragma mark - Lifecycle

- (void)dealloc {
}

- (void)loadView {
  UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
  [backgroundImageView setImage:[UIImage imageNamed:@"Default.png"]];
  self.view = backgroundImageView;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  // Parse Initialization
  [[WelcomeManager sharedInstance] setUpParseEnvironment];
}

#pragma mark - Private

@end