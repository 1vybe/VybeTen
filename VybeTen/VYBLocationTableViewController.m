//
//  VYBLocationTableViewController.m
//  VybeTen
//
//  Created by jinsuk on 8/27/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBLocationTableViewController.h"
#import "VYBAppDelegate.h"
#import "VYBHubViewController.h"
#import "VYBLocationTableViewCell.h"
#import "VYBPlayerViewController.h"
#import "VYBUsersTableViewController.h"
#import "VYBProfileViewController.h"
#import "VYBCache.h"

@interface VYBLocationTableViewController ()
@property (nonatomic, strong) NSArray *regions;

@property (nonatomic, copy) NSDictionary *vybesByLocation;
@property (nonatomic, copy) NSDictionary *usersByLocation;
@property (nonatomic, copy) NSDictionary *freshVybesByLocation;
@property (nonatomic, strong) NSArray *sortedKeys;
@end

@implementation VYBLocationTableViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // To remove empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlPulled:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    self.sortedKeys = [[NSArray alloc] init];
    
    [self getFreshVybes];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)refreshControlPulled:(id)sender {
    [self getFreshVybes];
}

- (void)getFreshVybes {
    [[VYBCache sharedCache] clearFreshVybes];
    
    NSString *functionName = @"get_fresh_vybes";
    [PFCloud callFunctionInBackground:functionName withParameters:@{} block:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (PFObject *aVybe in objects) {
                NSString *locString = aVybe[kVYBVybeLocationStringKey];
                NSArray *token = [locString componentsSeparatedByString:@","];
                if (token.count != 3)
                    continue;
                
                //NOTE: we discard the first location field (neighborhood)
                NSString *keyString = [NSString stringWithFormat:@"%@,%@", token[1], token[2]];
                [[VYBCache sharedCache] addFreshVybe:aVybe forLocation:keyString];
                [[VYBCache sharedCache] addFreshVybe:aVybe forUser:aVybe[kVYBVybeUserKey]];
            }
            self.freshVybesByLocation = [[VYBCache sharedCache] freshVybesByLocation];
            [self getUsersByLocation];
        }
        else {
            NSLog(@"%@", error);
        }
    }];
}

- (void)getUsersByLocation {
    [[VYBCache sharedCache] clearUsersByLocation];

    PFQuery *query = [PFUser query];
    // 24 TTL checking
    NSDate *someTimeAgo = [[NSDate alloc] initWithTimeIntervalSinceNow:-3600 * VYBE_TTL_HOURS];
    [query whereKey:kVYBUserLastVybedTimeKey greaterThanOrEqualTo:someTimeAgo];
    [query whereKey:kVYBUserUsernameKey notEqualTo:[PFUser currentUser][kVYBUserUsernameKey]];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (PFObject *aUser in objects) {
                NSArray *token = [aUser[kVYBUserLastVybedLocationKey] componentsSeparatedByString:@","];
                if (token.count != 3)
                    continue;
                
                //NOTE: we discard the first location field (neighborhood)
                NSString *keyString = [NSString stringWithFormat:@"%@,%@", token[1], token[2]];
                [[VYBCache sharedCache] addUser:aUser forLocation:keyString];
            }
            self.usersByLocation = [[VYBCache sharedCache] usersByLocation];
            [self getVybesByLocation];
        }
    }];
}


- (void)getVybesByLocation {
    [[VYBCache sharedCache] clearVybesByLocation];
    
    PFQuery *query = [PFQuery queryWithClassName:kVYBVybeClassKey];
    // 24 TTL checking
    NSDate *someTimeAgo = [[NSDate alloc] initWithTimeIntervalSinceNow:-3600 * VYBE_TTL_HOURS];
    [query whereKey:kVYBVybeTimestampKey greaterThanOrEqualTo:someTimeAgo];
    // Don't include urself
    [query whereKey:kVYBVybeUserKey notEqualTo:[PFUser currentUser]];
    [query whereKeyExists:kVYBVybeLocationStringKey];
    [query whereKey:kVYBVybeLocationStringKey notEqualTo:@""];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (PFObject *obj in objects) {
                NSString *locString = obj[kVYBVybeLocationStringKey];
                NSArray *token = [locString componentsSeparatedByString:@","];
                if (token.count != 3)
                    continue;
                
                //NOTE: we discard the first location field (neighborhood)
                NSString *keyString = [NSString stringWithFormat:@"%@,%@", token[1], token[2]];
                [[VYBCache sharedCache] addVybe:obj forLocation:keyString];
            }
            self.vybesByLocation = [[VYBCache sharedCache] vybesByLocation];
            // Sort by the number of FRESH vybes (descending)
            self.sortedKeys = [self.usersByLocation.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                return [self.freshVybesByLocation[obj1] count] < [self.freshVybesByLocation[obj2] count];
            }];
            
            [self.tableView reloadData];
            // NOTE: this should be called on the main thread
            [self setWatchAllButtonCount:self.freshVybesByLocation.allValues.count];
            
        }
        [self.refreshControl endRefreshing];
    }];
    
}



#pragma mark - UITableViewController

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sortedKeys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *LocationTableCellIdentifier = @"LocationTableCellIdentifier";

    VYBLocationTableViewCell *cell = (VYBLocationTableViewCell *)[tableView dequeueReusableCellWithIdentifier:LocationTableCellIdentifier];

    // NOTE: vybesByLocation
    NSString *locationKey = self.sortedKeys[indexPath.row];
    NSInteger vyCnt = [[self.vybesByLocation objectForKey:locationKey] count];
    NSInteger usrCnt = [[self.usersByLocation objectForKey:locationKey] count];
    NSInteger newVyCnt = [[self.freshVybesByLocation objectForKey:locationKey] count];
    [cell setLocationKey:locationKey];
    [cell setVybeCount:vyCnt];
    [cell setUserCount:usrCnt];
    [cell setFreshVybeCount:newVyCnt];
    
    //[cell.unwatchedVybeButton setContentMode:UIViewContentModeScaleAspectFit];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *locationKey = self.sortedKeys[indexPath.row];
    
    VYBUsersTableViewController *usersTable = [[VYBUsersTableViewController alloc] init];
    [usersTable setLocationKey:locationKey];
    [self.navigationController pushViewController:usersTable animated:NO];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    VYBHubViewController *hubVC = (VYBHubViewController *)self.parentViewController.parentViewController;
    if (!hubVC)
        return;
    
    [hubVC scrollViewBeganDragging:scrollView];
}

#pragma mark - ()

- (void)watchAll {
    
}

- (void)setWatchAllButtonCount:(NSInteger)count {
    VYBHubViewController *hubVC = (VYBHubViewController *)self.parentViewController.parentViewController;
    if (!hubVC)
        return;
    
    [hubVC setWatchAllButtonCount:count];
}

/*
#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here, for example:
    // Create the next view controller.
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:<#@"Nib name"#> bundle:nil];
    
    // Pass the selected object to the new view controller.
    
    // Push the view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
