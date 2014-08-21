//
//  VYBHubViewController.m
//  VybeTen
//
//  Created by jinsuk on 8/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBHubViewController.h"
#import "VYBRegionTableViewCell.h"
#import "VYBPlayerViewController.h"
#import "VYBFriendsViewController.h"

@interface VYBHubViewController ()
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISearchDisplayController *searchDisplay;
@property (nonatomic, strong) NSArray *regions;
@end

@implementation VYBHubViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlPulled:) forControlEvents:UIControlEventValueChanged];
    [self setRefreshControl:refreshControl];
    
    UIBarButtonItem *captureButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_capture.png"] style:UIBarButtonItemStylePlain target:self action:@selector(captureButtonPressed:)];
    UIBarButtonItem *playAllButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(allButtonItemPressed:)];
    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchButtonPressed:)];
    self.navigationItem.rightBarButtonItems = @[captureButton, playAllButton];

    UIBarButtonItem *profileButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_camera_front.png"] style:UIBarButtonItemStylePlain target:self action:@selector(profileButtonPressed:)];
    self.navigationItem.leftBarButtonItem = profileButton;
    
    self.searchBar = [[UISearchBar alloc] init];
    [self.searchBar sizeToFit];
    [self.view addSubview:self.searchBar];
    self.searchBar.hidden = YES;
    //self.tableView.tableHeaderView = self.searchBar;
    
    self.searchDisplay = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
        
    self.navigationController.navigationBarHidden = NO;
    
    NSString *functionName = @"get_regions";
    
    [PFCloud callFunctionInBackground:functionName withParameters:@{} block:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.regions = objects;
            NSLog(@"there are %d regions", self.regions.count);
            [self.tableView reloadData];
        } else {
            NSLog(@"get_regions failed: %@", error);
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.regions)
        return self.regions.count;
    else
        return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *RegionTableCellIdentifier = @"RegionTableCellIdentifer";
    VYBRegionTableViewCell *cell = (VYBRegionTableViewCell *)[tableView dequeueReusableCellWithIdentifier:RegionTableCellIdentifier];
    if (!cell) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"VYBRegionTableViewCell" owner:nil options:nil];
        cell = [nib lastObject];
        //NOTE: reuseIdentifier is set in xib file
    }
    //cell.textLabel.text = self.regions[indexPath.row][kVYBRegionNameKey];
    NSDictionary *aRegion = self.regions[indexPath.row];
    PFObject *pfRegion = aRegion[@"pfRegion"];
    NSNumber *vybeCount = aRegion[@"vybeCount"];
    NSNumber *userCount = aRegion[@"userCount"];
    
    [cell setName:pfRegion[kVYBRegionNameKey]];
    [cell setVybeCount:vybeCount];
    [cell setUserCount:userCount];

    NSLog(@"%@ has %@ vybes and %@ users", pfRegion[kVYBRegionNameKey], vybeCount, userCount);
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject *aRegion = self.regions[indexPath.row][@"pfRegion"];
    VYBFriendsViewController *friendsVC = [[VYBFriendsViewController alloc] init];
    [friendsVC setCurrRegion:aRegion];
    [self.navigationController pushViewController:friendsVC animated:NO];
    /*
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
    [playerVC setIsPublicMode:YES];
    [playerVC setCurrRegion:aRegion];
    [self.navigationController pushViewController:playerVC animated:NO];
    */
    
}

- (void)allButtonItemPressed:(id)sender {
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
    [playerVC setIsPublicMode:YES];
    [self.navigationController pushViewController:playerVC animated:NO];
}

- (void)searchButtonPressed:(id)sender {
    self.searchBar.hidden = NO;
    [self.searchBar becomeFirstResponder];
}

- (void)captureButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)profileButtonPressed:(id)sender {
    
}

#pragma mark - DeviceOrientation

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)refreshControlPulled:(id)sender {
    NSString *functionName = @"get_regions";
    
    [PFCloud callFunctionInBackground:functionName withParameters:@{} block:^(NSArray *objects, NSError *error) {
        [self.refreshControl endRefreshing];
        if (!error) {
            self.regions = objects;
            NSLog(@"there are %d regions", self.regions.count);
            [self.tableView reloadData];
        } else {
            NSLog(@"get_regions failed: %@", error);
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
