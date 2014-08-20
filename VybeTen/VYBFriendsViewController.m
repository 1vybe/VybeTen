//
//  VYBFriendsViewController.m
//  VybeTen
//
//  Created by jinsuk on 8/18/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBFriendsViewController.h"
#import "VYBPlayerViewController.h"

@interface VYBFriendsViewController ()
@property (nonatomic, strong) UISearchDisplayController *searchDisplay;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISegmentedControl *segmentControls;
@end

@implementation VYBFriendsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;

    [self.navigationController.navigationBar addSubview:self.segmentControls];
    CGPoint center = self.segmentControls.center;
    center.x = self.navigationController.navigationBar.center.x;
    self.segmentControls.center = center;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBarHidden = YES;
    
    [self.segmentControls removeFromSuperview];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *playAllButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playAllButtonPressed:)];
    self.navigationItem.rightBarButtonItem = playAllButton;
    
    self.segmentControls = [[UISegmentedControl alloc] initWithItems:@[@"Following", @"Follower"]];
    [self.segmentControls addTarget:self action:@selector(segmentControlChanged:) forControlEvents:UIControlEventValueChanged];

    self.searchBar = [[UISearchBar alloc] init];
    [self.searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchBar;

    
    self.searchDisplay = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    
    // Do any additional setup after loading the view from its nib.
}

#pragma mark - PFQueryTableViewController

- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:kVYBActivityClassKey];
    return query;
}

#pragma mark - ()

- (void)segmentControlChanged:(id)sender {
    
}

- (void)playAllButtonPressed:(id)sender {
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
    [playerVC setIsPublicMode:NO];
    [self.navigationController pushViewController:playerVC animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
