//
//  VYBUsersTableViewController.m
//  VybeTen
//
//  Created by jinsuk on 8/28/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBUsersTableViewController.h"
#import "VYBUserTableViewCell.h"
#import "VYBProfileViewController.h"
#import "VYBPlayerViewController.h"
#import "VYBCache.h"

@interface VYBUsersTableViewController ()
@property (nonatomic, copy) NSArray *users;
@property (nonatomic) NSMutableDictionary *vybesFromHereByUser;
@property (nonatomic) NSMutableDictionary *freshVybesFromHereByUser;
@end

@implementation VYBUsersTableViewController {
    UIImageView *countryFlagImageView;
}
@synthesize users, vybesFromHereByUser, freshVybesFromHereByUser, freshVybes;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBCacheFreshVybeCountChangedNotification object:nil];
}


- (void)viewDidLoad {
    [super viewDidLoad];
        
    //NOTE: To remove empty cells.
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(freshVybeCountChanged) name:VYBCacheFreshVybeCountChangedNotification object:nil];

    [self freshVybeCountChanged];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!users)
        return 0;
    return users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *UserTableCellIdentifier = @"UserTableCellIdentifier";
    
    VYBUserTableViewCell *cell = (VYBUserTableViewCell *)[tableView dequeueReusableCellWithIdentifier:UserTableCellIdentifier];
    if (!cell) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"VYBUserTableViewCell" owner:nil options:nil] firstObject];
    }
    
    PFObject *aUser = users[indexPath.row];
    
    // NOTE: freshVybesByUser dictionary take PFUser object's objectID as a key
    NSArray *freshVybeFromHereByThisUser = [self.freshVybesFromHereByUser objectForKey:aUser.objectId];
    NSInteger freshCount = (freshVybeFromHereByThisUser) ? ([freshVybeFromHereByThisUser count]) : 0;
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
    
    NSInteger allVybeCount = [[self.vybesFromHereByUser objectForKey:aUser.objectId] count];
    [cell setVybeCount:allVybeCount];
    
    [cell setDelegate:self];
    [cell setUserObjID:aUser.objectId];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject *aUser = users[indexPath.row];
    VYBProfileViewController *profileVC = [[VYBProfileViewController alloc] init];
    [profileVC setUser:aUser];
    [self.navigationController pushViewController:profileVC animated:NO];
}


#pragma mark - ()

- (void)watchNewVybesFromUser:(NSString *)aUserID {
    NSArray *playList = [freshVybesFromHereByUser objectForKey:aUserID];
    if (playList && playList.count > 0) {
        VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] initWithNibName:@"VYBPlayerViewController" bundle:nil];
        [playerVC setVybePlaylist:playList];
        [self presentViewController:playerVC animated:NO completion:nil];
    }
}


#pragma mark - VYBCacheFreshVybeCountChangedNotification

- (void)freshVybeCountChanged {
    
    NSArray *vybes = [[VYBCache sharedCache] vybesForLocation:self.locationKey];
    vybesFromHereByUser = [[NSMutableDictionary alloc] init];
    for (PFObject *aVybe in vybes) {
        PFObject *aUser = aVybe[kVYBVybeUserKey];
        NSArray *arr = [vybesFromHereByUser objectForKey:aUser.objectId];
        if (!arr)
            arr = [NSArray arrayWithObject:aVybe];
        else
            arr = [arr arrayByAddingObject:aVybe];
        [vybesFromHereByUser setObject:arr forKey:aUser.objectId];
    }
    
    freshVybes = [[VYBCache sharedCache] freshVybesForLocation:self.locationKey];
    freshVybesFromHereByUser = [[NSMutableDictionary alloc] init];
    for (PFObject *fVybe in freshVybes) {
        PFObject *aUser = fVybe[kVYBVybeUserKey];
        NSArray *arr = [freshVybesFromHereByUser objectForKey:aUser.objectId];
        if (!arr)
            arr = [NSArray arrayWithObject:fVybe];
        else
            arr = [arr arrayByAddingObject:fVybe];
        [freshVybesFromHereByUser setObject:arr forKey:aUser.objectId];
    }
    
    
    users = [[VYBCache sharedCache] usersForLocation:self.locationKey];
    users = [users sortedArrayUsingComparator:^NSComparisonResult(PFObject *user1, PFObject *user2) {
        return [[freshVybesFromHereByUser objectForKey:user1.objectId] count] < [[freshVybesFromHereByUser objectForKey:user2.objectId] count];
    }];
    
    // Send a msg to container controller to update watchAllCount
    if (self.delegate && [self.delegate respondsToSelector:@selector(freshVybeCountChanged)]) {
        [self.delegate performSelector:@selector(freshVybeCountChanged) withObject:nil];
    }
    
    [self.tableView reloadData];
}

#pragma mark - Orientation

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationPortrait;
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
