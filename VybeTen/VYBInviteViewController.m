//
//  VYBInviteViewController.m
//  VybeTen
//
//  Created by jinsuk on 5/2/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBInviteViewController.h"
#import "VYBMenuViewController.h"

@implementation VYBInviteViewController {
    UIView *topBar;
    UILabel *currentTabLabel;
    UIButton *backButton;
    
    UIView *sideBar;
    UIButton *captureButton;
    UIButton *menuButton;
    UIButton *contactsTabButton;
    UIButton *facebookTabButton;
    UIButton *twitterTabButton;
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
    
    // Adding BACK button
    frame = CGRectMake(0, 0, 50, 50);
    backButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *backImg = [UIImage imageNamed:@"button_back.png"];
    [backButton setImage:backImg forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(goBack:) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:backButton];
    // Adding Label
    frame = CGRectMake(10, 0, 150, 50);
    currentTabLabel = [[UILabel alloc] initWithFrame:frame];
    [currentTabLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20.0]];
    [currentTabLabel setTextColor:[UIColor whiteColor]];
    [currentTabLabel setText:@"I N V I T E   F R I E N D S"];
    [topBar addSubview:currentTabLabel];
    
    // Adding a transparent SIDEBAR
    frame = CGRectMake(self.view.bounds.size.height - 50, 0, 50, self.view.bounds.size.width);
    sideBar = [[UIView alloc] initWithFrame:frame];
    [self.view addSubview:sideBar];
    // Adding MENU button
    frame = CGRectMake(0, 0, 50, 50);
    menuButton = [[UIButton alloc] initWithFrame:frame];
    [menuButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    UIImage *menuImg = [UIImage imageNamed:@"button_menu.png"];
    [menuButton setImage:menuImg forState:UIControlStateNormal];
    [menuButton addTarget:self action:@selector(goToMenu:) forControlEvents:UIControlEventTouchUpInside];
    [sideBar addSubview:menuButton];
    // Adding CONTACTS Tab button
    frame = CGRectMake(0, 50, 50, (self.view.bounds.size.width - 100)/3);
    contactsTabButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *contactsImg = [UIImage imageNamed:@"button_contacts_tab.png"];
    [contactsTabButton setImage:contactsImg forState:UIControlStateNormal];
    // CONTACTS Tab is selected by default
    [contactsTabButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [contactsTabButton addTarget:self action:@selector(contactsTabSelected:) forControlEvents:UIControlEventTouchUpInside];
    [sideBar addSubview:contactsTabButton];
    
    // Adding FACEBOOK Friends Tab button
    frame = CGRectMake(0, 50 + (self.view.bounds.size.width - 100)/3, 50, (self.view.bounds.size.width - 100)/3);
    facebookTabButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *fbImg = [UIImage imageNamed:@"button_facebook_tab.png"];
    [facebookTabButton setImage:fbImg forState:UIControlStateNormal];
    [facebookTabButton addTarget:self action:@selector(facebookTabSelected:) forControlEvents:UIControlEventTouchUpInside];
    [sideBar addSubview:facebookTabButton];
    
    // Adding TWITTER Friends Tab button
    frame = CGRectMake(0, 50 + (self.view.bounds.size.width - 100)*2/3, 50, (self.view.bounds.size.width - 100)/3);
    twitterTabButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *twtImg = [UIImage imageNamed:@"button_twitter_tab.png"];
    [twitterTabButton setImage:twtImg forState:UIControlStateNormal];
    [twitterTabButton addTarget:self action:@selector(twitterTabSelected:) forControlEvents:UIControlEventTouchUpInside];
    [sideBar addSubview:twitterTabButton];
    
    // Adding CAPTURE button
    frame = CGRectMake(0, self.view.bounds.size.width - 50, 50, 50);
    captureButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *captureImg = [UIImage imageNamed:@"button_vybe.png"];
    [captureButton setImage:captureImg forState:UIControlStateNormal];
    //[captureButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [captureButton addTarget:self action:@selector(captureVybe:) forControlEvents:UIControlEventTouchUpInside];
    [sideBar addSubview:captureButton];
}

- (void)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
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

- (void)contactsTabSelected:(id)sender {
    
}

- (void)facebookTabSelected:(id)sender {
    
}

- (void)twitterTabSelected:(id)sender {
    
}

- (void)captureVybe:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
