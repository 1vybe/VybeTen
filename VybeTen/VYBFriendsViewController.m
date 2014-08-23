//
//  VYBFriendsViewController.m
//  VybeTen
//
//  Created by jinsuk on 8/18/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBFriendsViewController.h"
#import "VYBPlayerViewController.h"
#import "VYBFriendTableViewCell.h"

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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
        
    [self.segmentControls removeFromSuperview];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = self.currRegion[kVYBRegionNameKey];
    
 }

#pragma mark - PFQueryTableViewController

- (PFQuery *)queryForTable {
    PFQuery *query = [PFUser query];
    
    PFQuery *innerQuery = [PFQuery queryWithClassName:kVYBVybeClassKey];
    NSString *countryCode = self.currRegion[kVYBRegionCodeKey];
    // 24 TTL checking
    NSDate *someTimeAgo = [[NSDate alloc] initWithTimeIntervalSinceNow:-3600 * VYBE_TTL_HOURS];
    [innerQuery whereKey:kVYBVybeTimestampKey greaterThanOrEqualTo:someTimeAgo];
    //[innerQuery whereKey:kVYBVybeCountryCodeKey equalTo:countryCode];
    
    //[query whereKey:kVYBUserMostRecentVybeKey matchesQuery:innerQuery];
    // Don't include urself
    [query whereKey:kVYBUserUsernameKey notEqualTo:[PFUser currentUser][kVYBUserUsernameKey]];
    return query;
}

#pragma mark - UITableViewController

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *FriendTableCellIdentifier = @"FriendTableCellIdentifer";
    VYBFriendTableViewCell *cell = (VYBFriendTableViewCell *)[tableView dequeueReusableCellWithIdentifier:FriendTableCellIdentifier];
    if (!cell) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"VYBFriendTableViewCell" owner:nil options:nil];
        cell = [nib lastObject];
        //NOTE: reuseIdentifier is set in xib file
    }
    cell.nameLabel.text = object[kVYBUserUsernameKey];

    return cell;
}



#pragma mark - ()

- (void)segmentControlChanged:(id)sender {
    
}

- (void)playAllButtonPressed:(id)sender {
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
    [self.navigationController pushViewController:playerVC animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
