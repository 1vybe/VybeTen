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

#import "Vybe-Swift.h"

@implementation VYBWelcomeViewController

#pragma mark - Lifecycle

- (void)dealloc {
}

- (void)loadView {
  UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
  [backgroundImageView setBackgroundColor:[UIColor blackColor]];
  self.view = backgroundImageView;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Parse Initialization
  [[WelcomeManager sharedInstance] setUpParseEnvironment];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  [[WelcomeManager sharedInstance] checkLogInStatus];
}

#pragma mark - Private

@end