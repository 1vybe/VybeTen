//
//  VYBFriendsViewController.m
//  VybeTen
//
//  Created by jinsuk on 4/25/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBFriendsViewController.h"
#import "VYBMenuViewController.h"
#import "VYBInviteViewController.h"

@implementation VYBFriendsViewController {
    UIView *topBar;
    UILabel *currentTabLabel;
    UILabel *createButton;
    
    UIView *sideBar;
    UIButton *searchButton;
    UIButton *captureButton;
    UIButton *menuButton;
    
}

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
    
    UIToolbar *backView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.height, self.view.bounds.size.width)];
    [backView setBarStyle:UIBarStyleBlack];
    [self.view addSubview:backView];
    
    // Adding a dark TOPBAR
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.height - 50, 50);
    topBar = [[UIView alloc] initWithFrame:frame];
    [topBar setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.1]];
    [self.view addSubview:topBar];
    
    // Adding SEARCH button
    frame = CGRectMake(self.view.bounds.size.height - 100, 0, 50, 50);
    searchButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *searchImg = [UIImage imageNamed:@"button_search.png"];
    [searchButton setImage:searchImg forState:UIControlStateNormal];
    [topBar addSubview:searchButton];
    // Adding Label
    frame = CGRectMake(10, 0, 150, 50);
    currentTabLabel = [[UILabel alloc] initWithFrame:frame];
    [currentTabLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20.0]];
    [currentTabLabel setTextColor:[UIColor whiteColor]];
    [currentTabLabel setText:@"F R I E N D S"];
    [topBar addSubview:currentTabLabel];
    // Adding CREATE(Tribe) button
    frame = CGRectMake(self.view.bounds.size.height - 150, 0, 50, 50);
    createButton = [[UILabel alloc] initWithFrame:frame];
    [createButton setText:@"+"];
    [createButton setTextColor:[UIColor whiteColor]];
    [createButton setTextAlignment:NSTextAlignmentCenter];
    [createButton setFont:[UIFont fontWithName:@"Montreal-Xlight" size:40]];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addFriend:)];
    [createButton addGestureRecognizer:tap];
    [createButton setUserInteractionEnabled:YES];
    [topBar addSubview:createButton];
    
    // Adding a dark SIDEBAR
    frame = CGRectMake(self.view.bounds.size.height - 50, 0, 50, self.view.bounds.size.width);
    sideBar = [[UIView alloc] initWithFrame:frame];
    [sideBar setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [self.view addSubview:sideBar];
    // Adding MENU button
    frame = CGRectMake(0, 0, 50, 50);
    menuButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *menuImg = [UIImage imageNamed:@"button_menu.png"];
    [menuButton setImage:menuImg forState:UIControlStateNormal];
    //[menuButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [menuButton addTarget:self action:@selector(goToMenu:) forControlEvents:UIControlEventTouchUpInside];
    [sideBar addSubview:menuButton];
    
    // Adding CAPTURE button
    frame = CGRectMake(0, self.view.bounds.size.width - 50, 50, 50);
    captureButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *captureImg = [UIImage imageNamed:@"button_vybe.png"];
    [captureButton setImage:captureImg forState:UIControlStateNormal];
    //[captureButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [captureButton addTarget:self action:@selector(captureVybe:) forControlEvents:UIControlEventTouchUpInside];
    [sideBar addSubview:captureButton];
    
}

- (void)goToMenu:(id)sender {
    VYBMenuViewController *menuVC = [[VYBMenuViewController alloc] init];
    menuVC.view.backgroundColor = [UIColor clearColor];
    menuVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    //[menuVC setTransitioningDelegate:transitionController];
    //menuVC.modalPresentationStyle = UIModalPresentationCurrentContext;
    //self.modalPresentationStyle = UIModalPresentationCurrentContext;
    [self.navigationController presentViewController:menuVC animated:YES completion:nil];
}

- (void)captureVybe:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)addFriend:(id)sender {
    VYBInviteViewController *inviteVC = [[VYBInviteViewController alloc] init];
    [self.navigationController pushViewController:inviteVC animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}



@end
