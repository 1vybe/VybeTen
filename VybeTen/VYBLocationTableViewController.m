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
#import "VYBPlayerControlViewController.h"
#import "VYBUsersTableViewController.h"
#import "VYBProfileViewController.h"
#import "VYBCache.h"
#import "VYBUtility.h"

@interface VYBLocationTableViewController ()

@property (nonatomic, copy) NSDictionary *vybesByLocation;
@property (nonatomic, copy) NSDictionary *usersByLocation;
@property (nonatomic, copy) NSDictionary *freshVybesByLocation;
@property (nonatomic, strong) NSArray *sortedKeys;

@end

@implementation VYBLocationTableViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBCacheFreshVybeCountChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBUtilityVybesLoadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBFreshVybeFeedFetchedFromRemoteNotification object:nil];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //To remove empty cells.
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlPulled:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(vybesLoaded) name:VYBUtilityVybesLoadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(freshVybeCountChanged) name:VYBCacheFreshVybeCountChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(freshVybeCountChanged) name:VYBFreshVybeFeedFetchedFromRemoteNotification object:nil];

    if (!self.sortedKeys)
        [self vybesLoaded];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

- (void)refreshControlPulled:(id)sender {
    if ( [[VYBCache sharedCache] vybesByLocation] ) {
        [VYBUtility fetchFreshVybeFeedWithCompletion:^(BOOL succeeded, NSError *error) {
            [self.refreshControl endRefreshing];
        }];
    } else {
        [VYBUtility getVybesByLocationAndByUser:^(BOOL succeeded, NSError *error) {
            [VYBUtility fetchFreshVybeFeedWithCompletion:^(BOOL succeeded, NSError *error) {
                [self.refreshControl endRefreshing];
            }];
        }];
    }
}

#pragma mark - UITableViewController

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 62.0f;
}

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


#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    VYBHubViewController *hubVC = (VYBHubViewController *)self.parentViewController.parentViewController;
    if (!hubVC) {
        NSLog(@"no hubVC");
        return;
    }
    
    [hubVC scrollViewBeganDragging:scrollView];
}


#pragma mark - NSNotifications

- (void)freshVybeCountChanged {
    self.freshVybesByLocation = [[VYBCache sharedCache] freshVybesByLocation];
    self.usersByLocation = [[VYBCache sharedCache] usersByLocation];
    self.vybesByLocation = [[VYBCache sharedCache] vybesByLocation];

    // Sort by the number of FRESH vybes (descending)
    self.sortedKeys = [self.vybesByLocation.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [self.freshVybesByLocation[obj1] count] < [self.freshVybesByLocation[obj2] count];
    }];
    [self.tableView reloadData];
}

- (void)vybesLoaded {
    if (![[VYBCache sharedCache] freshVybesByLocation]) {
        [VYBUtility fetchFreshVybeFeedWithCompletion:^(BOOL succeeded, NSError *error) {
            [self freshVybesByLocation];
        }];
    }
    else if ( [[VYBCache sharedCache] vybesByLocation] )
        [self freshVybeCountChanged];
    else
        return;
}

#pragma mark - ()

- (void)watchNewVybesFromLocation:(NSString *)locationKey {
    NSArray *vybes = [self.freshVybesByLocation objectForKey:locationKey];
    if (vybes && vybes.count > 0) {
        VYBPlayerControlViewController *playerController = [[VYBPlayerControlViewController alloc] initWithNibName:@"VYBPlayerControlViewController" bundle:nil];
        [playerController setVybePlaylist:vybes];
        [self presentViewController:playerController animated:NO completion:^{
            [playerController beginPlayingFrom:0];
        }];
    }
}

@end
