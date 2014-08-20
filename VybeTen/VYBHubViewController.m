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
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *playAllButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(allButtonItemPressed:)];
    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchButtonPressed:)];
    self.navigationItem.rightBarButtonItems = @[playAllButton, searchButton];

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
    
    self.navigationItem.backBarButtonItem.title = @"";
    
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
    PFObject *aRegion = self.regions[indexPath.row];
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
    [playerVC setIsPublicMode:YES];
    [playerVC setCurrRegion:aRegion];
    [self.navigationController pushViewController:playerVC animated:NO];
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


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
