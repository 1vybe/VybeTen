//
//  VYBFollowingTableViewController.m
//  VybeTen
//
//  Created by jinsuk on 8/28/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBFollowingTableViewController.h"
#import "VYBUserTableViewCell.h"
#import "VYBProfileViewController.h"
#import "VYBPlayerViewController.h"
#import "VYBHubViewController.h"
#import "VYBCache.h"
#import "VYBUtility.h"

@interface VYBFollowingTableViewController ()
@property (nonatomic, copy) NSDictionary *vybesByUser;
@property (nonatomic, copy) NSDictionary *freshVybesByUser;
@property (nonatomic) NSArray *sortedUsers;
@end

@implementation VYBFollowingTableViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBCacheFreshVybeCountChangedNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    //To remove empty cells.
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(vybesLoaded) name:VYBHubScreenVybesLoadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(freshVybeCountChanged) name:VYBCacheFreshVybeCountChangedNotification object:nil];
    
    [self freshVybeCountChanged];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITableViewController

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 62.0f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sortedUsers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *UserTableViewCellIdentifier = @"UserTableViewCellIdentifier";
    VYBUserTableViewCell *cell = (VYBUserTableViewCell *)[tableView dequeueReusableCellWithIdentifier:UserTableViewCellIdentifier];
    if (!cell) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"VYBUserTableViewCell" owner:nil options:nil];
        cell = [nib firstObject];
        //NOTE: reuseIdentifier is set in xib file
    }

    PFObject *aUser = self.sortedUsers[indexPath.row];
    // NOTE: freshVybesByUser dictionary take PFUser object's objectID as a key
    NSInteger freshCount = (self.freshVybesByUser) ? ([[self.freshVybesByUser objectForKey:aUser.objectId] count]) : 0;
    [cell setFreshVybeCount:freshCount];
    
    NSString *lowerUsername = [(NSString *)aUser[kVYBUserUsernameKey] lowercaseString];
    // TODO: user PFImageView of PFTableViewCell
    [cell.nameLabel setText:lowerUsername];
    
    PFFile *profile = aUser[kVYBUserProfilePicMediumKey];
    [profile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
            cell.profileImageView.image = [VYBUtility maskImage:[UIImage imageWithData:data] withMask:[UIImage imageNamed:@"thumbnail_mask"]];
        }
    }];
    
    NSInteger allVybeCount = [[self.vybesByUser objectForKey:aUser.objectId] count];
    NSArray *locations = [aUser[kVYBUserLastVybedLocationKey] componentsSeparatedByString:@","];
    NSString *cityName = locations[1];
    [cell.countLabel setText:[NSString stringWithFormat:@"%ld Vybes From %@", (long)allVybeCount, cityName]];
    
    [cell setUserObjID:aUser.objectId];
    [cell setDelegate:self];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject *aUser = self.sortedUsers[indexPath.row];
    VYBProfileViewController *profileVC = [[VYBProfileViewController alloc] init];
    [profileVC setUser:aUser];
    [self.navigationController pushViewController:profileVC animated:NO];
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    VYBHubViewController *hubVC = (VYBHubViewController *)self.parentViewController.parentViewController;
    if (!hubVC)
        return;
    
    [hubVC scrollViewBeganDragging:scrollView];
}

#pragma amrk - ()

- (void)watchNewVybesFromUser:(NSString *)aUserID {
    NSArray *vybes = [self.freshVybesByUser objectForKey:aUserID];
    if (vybes && vybes.count > 0) {
        VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] initWithNibName:@"VYBPlayerViewController" bundle:nil];
        [playerVC setVybePlaylist:vybes];
        [self presentViewController:playerVC animated:NO completion:nil];
    }
}

#pragma mark - NSNotifications

- (void)freshVybeCountChanged {
    self.vybesByUser = [[VYBCache sharedCache] vybesByUser];
    self.freshVybesByUser = [[VYBCache sharedCache] freshVybesByUser];
    NSArray *activeUsers = [[VYBCache sharedCache] activeUsers];
    
    self.sortedUsers = [activeUsers sortedArrayUsingComparator:^NSComparisonResult(PFObject *user1, PFObject *user2) {
        return [[self.freshVybesByUser objectForKey:user1.objectId] count] < [[self.freshVybesByUser objectForKey:user2.objectId] count];
    }];
    
    [self.tableView reloadData];
}

- (void)vybesLoaded {
    [self freshVybeCountChanged];
}


@end
