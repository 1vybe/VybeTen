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

@interface VYBFollowingTableViewController ()
@property (nonatomic, copy) NSDictionary *vybesByUser;
@property (nonatomic, copy) NSDictionary *freshVybesByUser;
@property (nonatomic, strong) NSArray *sortedUsers;
@end

@implementation VYBFollowingTableViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBCacheFreshVybeCountChangedNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    //NOTE: To remove empty cells.
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(freshVybeCountChanged) name:VYBCacheFreshVybeCountChangedNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewController

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
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
            UIImage *profileImg = [UIImage imageWithData:data];
            cell.profileImageView.image = profileImg;
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

#pragma mark - PFQueryTableViewController 

- (PFQuery *)queryForTable {
    PFQuery *query = [PFUser query];
    // 24 TTL checking
    NSDate *someTimeAgo = [[NSDate alloc] initWithTimeIntervalSinceNow:-3600 * VYBE_TTL_HOURS];
    [query whereKey:kVYBUserLastVybedTimeKey greaterThanOrEqualTo:someTimeAgo];
    // Don't include urself
    [query whereKey:kVYBUserUsernameKey notEqualTo:[PFUser currentUser][kVYBUserUsernameKey]];
    [query whereKey:kVYBUserLastVybedLocationKey notEqualTo:@""];
    [query orderByDescending:kVYBUserLastVybedTimeKey];
    
    return query;
}

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    
    // TODO: freshVybesByUser should be updated by refresh control
    [self freshVybeCountChanged];
}

#pragma amrk - ()

- (void)freshVybeCountChanged {
    self.vybesByUser = [[VYBCache sharedCache] vybesByUser];
    self.freshVybesByUser = [[VYBCache sharedCache] freshVybesByUser];
    
    self.sortedUsers = [self.objects sortedArrayUsingComparator:^NSComparisonResult(PFObject *user1, PFObject *user2) {
        return [[self.freshVybesByUser objectForKey:user1.objectId] count] < [[self.freshVybesByUser objectForKey:user2.objectId] count];
    }];
    
    [self.tableView reloadData];
}

- (void)watchNewVybesFromUser:(NSString *)aUserID {
    NSArray *vybes = [self.freshVybesByUser objectForKey:aUserID];
    if (vybes && vybes.count > 0) {
        VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] initWithNibName:@"VYBPlayerViewController" bundle:nil];
        [playerVC setVybePlaylist:vybes];
        [self presentViewController:playerVC animated:NO completion:nil];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
