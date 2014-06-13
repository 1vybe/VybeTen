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

@implementation VYBMainPageViewController
@synthesize scrollView = _scrollView;
@synthesize controllers = _controllers;

- (void)viewDidLoad {
    NSLog(@"_view: %@", NSStringFromCGRect(self.view.frame));
    [super viewDidLoad];
    NSLog(@"AFTER.. _view: %@", NSStringFromCGRect(self.view.frame));

    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.height, self.view.bounds.size.width)];
    [self.view addSubview:self.scrollView];
    self.scrollView.contentSize = CGSizeMake(self.view.bounds.size.height, self.view.bounds.size.width * 2);
    self.scrollView.pagingEnabled = YES;

    
    self.controllers = [[NSMutableArray alloc] init];
    
    VYBCaptureViewController *captureVC = [[VYBCaptureViewController alloc] init];
    //VYBTribesViewController *tribeVC = [[VYBTribesViewController alloc] initWithPosition:1];
    //[self.scrollView addSubview:tribeVC.view];
    [self.scrollView addSubview:captureVC.view];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.height, self.view.bounds.size.width)];
    [self.view addSubview:self.scrollView];
    self.scrollView.contentSize = CGSizeMake(self.view.bounds.size.height, self.view.bounds.size.width * 2);
    self.scrollView.pagingEnabled = YES;
    
    
    self.controllers = [[NSMutableArray alloc] init];
    
    VYBCaptureViewController *captureVC = [[VYBCaptureViewController alloc] init];
    //VYBTribesViewController *tribeVC = [[VYBTribesViewController alloc] initWithPosition:1];
    //[self.scrollView addSubview:tribeVC.view];
    [self.scrollView addSubview:captureVC.view];
}

@end
