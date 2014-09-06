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

@property (nonatomic, copy) NSDictionary *vybesByLocation;
@property (nonatomic, copy) NSDictionary *usersByLocation;
@property (nonatomic, copy) NSDictionary *freshVybesByLocation;
@property (nonatomic, strong) NSArray *sortedKeys;

@end

@implementation VYBLocationTableViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBCacheFreshVybeCountChangedNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // To remove empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlPulled:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(freshVybeCountChanged) name:VYBCacheFreshVybeCountChangedNotification object:nil];
    
    self.sortedKeys = [[NSArray alloc] init];
    
    [self getFreshVybes];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
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
                [[VYBCache sharedCache] addFreshVybe:aVybe];
            }
            [self getUsersByLocation];
        }
        else {
            [self.refreshControl endRefreshing];
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
            [self getVybesByLocationAndByUser];
        } else {
            [self.refreshControl endRefreshing];
        }
    }];
}


- (void)getVybesByLocationAndByUser {
    [[VYBCache sharedCache] clearVybesByLocation];
    [[VYBCache sharedCache] clearVybesByUser];
    
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
                [[VYBCache sharedCache] addVybe:obj forUser:obj[kVYBVybeUserKey]];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:VYBCacheFreshVybeCountChangedNotification object:nil];
            });
            
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
    
    [cell setDelegate:self];
    
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

- (void)watchNewVybesFromLocation:(NSString *)locationKey {
    NSArray *vybes = [self.freshVybesByLocation objectForKey:locationKey];
    if (vybes && vybes.count > 0) {
        VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] initWithNibName:@"VYBPlayerViewController" bundle:nil];
        [playerVC setPresentingVC:self];
        [playerVC setVybePlaylist:vybes];
        [self presentViewController:playerVC animated:NO completion:nil];
    }
}

- (void)freshVybeCountChanged {
    self.freshVybesByLocation = [[VYBCache sharedCache] freshVybesByLocation];
    self.usersByLocation = [[VYBCache sharedCache] usersByLocation];
    self.vybesByLocation = [[VYBCache sharedCache] vybesByLocation];

    // Sort by the number of FRESH vybes (descending)
    self.sortedKeys = [self.usersByLocation.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [self.freshVybesByLocation[obj1] count] < [self.freshVybesByLocation[obj2] count];
    }];
    [self.tableView reloadData];
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
