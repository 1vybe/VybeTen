//
//  VYBFriendsViewController.m
//  VybeTen
//
//  Created by jinsuk on 4/25/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBAddMemberViewController.h"
#import "VYBInviteViewController.h"
#import "VYBCache.h"
#import "MBProgressHUD.h"
#import "VYBImageStore.h"
#import "VYBFriendCollectionCell.h"
#import "VYBUtility.h"

@implementation VYBAddMemberViewController {
    UIView *topBar;
    UILabel *screenTitleLabel;
    
    UIBarButtonItem *confirmButton;
    
    UISegmentedControl *segmentedControl;
    UIButton *alreadyMembersTabButton;
    UIButton *nonMembersTabButton;
    
    BOOL membersTabSelected;
    
    NSMutableArray *selectedUsers;
    //NSMutableArray *alreadyMembers;

    /*
    UILabel *inviteButton;
    NSMutableArray *nonMembers;
    */
}


- (id)initWithTribe:(PFObject *)aTribe {
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        self.tribe = aTribe;
        
        selectedUsers = [[NSMutableArray alloc] init];
        
        self.paginationEnabled = NO;
    }
    
    return self;
}

- (void)loadView {
    [super loadView];
    
    segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Members", @"Friends"]];
    segmentedControl.selectedSegmentIndex = 0;
    [segmentedControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = segmentedControl;
    
    confirmButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_check.png"]
                                                                              style:UIBarButtonItemStylePlain target:self action:@selector(confirmButtonPressed:)];
    self.navigationItem.rightBarButtonItem = confirmButton;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self syncUIElementsWithSegment];
    
    [self refreshFollowStatusForFriends];
}

#pragma mark - PFQueryTableView

- (PFQuery *)queryForTable {
    // Members
    if (segmentedControl.selectedSegmentIndex == 0) {
        return [self queryForMembers];
    } else { // Friends
        return [self queryForFriends];
    }
}

- (PFQuery *)queryForMembers {
    PFRelation *members = [self.tribe relationForKey:kVYBTribeMembersKey];
    PFQuery *query = [members query];
    [query whereKey:@"objectId" notEqualTo:[[PFUser currentUser] objectId]];
    
    /*
    if (self.objects.count == 0) {
        query.cachePolicy = kPFCachePolicyCacheElseNetwork;
    }
    */
    
    [query orderByAscending:kVYBUserDisplayNameKey];
    
    return query;
}

- (PFQuery *)queryForFriends {
    //TODO: exclude members
    
    PFQuery *friendsQuery = [PFUser query];
    PFQuery *membersQuery = [self queryForMembers];
    //PFQuery *query = [PFUser query];
    
    NSArray *facebookFriends = [[VYBCache sharedCache] facebookFriends];
    
    [friendsQuery whereKey:kVYBUserFacebookIDKey containedIn:facebookFriends];
    
    [friendsQuery whereKey:@"objectId" doesNotMatchKey:@"objectId" inQuery:membersQuery];
    
    if (self.objects.count == 0) {
        friendsQuery.cachePolicy = kPFCachePolicyCacheElseNetwork;
    }
    
    [friendsQuery orderByAscending:kVYBUserDisplayNameKey];
    
    return friendsQuery;
}


#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *MemberCellIdentifier = @"MemberCellIdentifier";
    
    VYBFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:MemberCellIdentifier];
    
    if (!cell) {
        cell = [[VYBFriendCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MemberCellIdentifier];
        cell.delegate = self;
    }
    [cell setUser:(PFUser *)object];
    
    [cell setSelected:[selectedUsers containsObject:object]];
    cell.followButton.selected = [[VYBCache sharedCache] followStatusForUser:(PFUser *)object];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    VYBFriendCell *cell = (VYBFriendCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:YES];
    PFObject *aUser = [self objectAtIndexPath:indexPath];
    [selectedUsers addObject:aUser];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    VYBFriendCell *cell = (VYBFriendCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:NO];
    PFObject *aUser = [self objectAtIndexPath:indexPath];
    [selectedUsers removeObject:aUser];
}



#pragma mark - VYBVybeCellDelegate

- (void)cell:(VYBFriendCell *)cellView didTapFollowButton:(PFUser *)aUser {
    [self shouldToggleFollowFriendForCell:cellView];
}


#pragma mark - UITableViewCellDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.objects.count) {
        return [VYBFriendCell heightForCell];
    } else {
        return 44.0f;
    }
}


#pragma mark - ()

- (void)refreshFollowStatusForFriends {
    // PFQuery for retrieving a list of friends on Vybe
    PFQuery *friendsQuery = [PFUser query];
    NSArray *facebookFriends = [[VYBCache sharedCache] facebookFriends];
    [friendsQuery whereKey:kVYBUserFacebookIDKey containedIn:facebookFriends];

    PFQuery *isFollowedByCurrentUser = [PFQuery queryWithClassName:kVYBActivityClassKey];
    [isFollowedByCurrentUser whereKey:kVYBActivityTypeKey equalTo:kVYBActivityTypeFollow];
    [isFollowedByCurrentUser whereKey:kVYBActivityFromUserKey equalTo:[PFUser currentUser]];
    [isFollowedByCurrentUser whereKey:kVYBActivityToUserKey matchesQuery:friendsQuery];
    [isFollowedByCurrentUser findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (PFObject *following in objects) {
                [[VYBCache sharedCache] setFollowStatus:YES user:following[kVYBActivityToUserKey]];
            }
            [self.tableView reloadData];
        }
    }];
}

- (void)segmentChanged:(id)sender {
    [self loadObjects];
    [self syncUIElementsWithSegment];
}

- (void)syncUIElementsWithSegment {
    // Members
    if (segmentedControl.selectedSegmentIndex == 0) {
        self.tableView.allowsMultipleSelection = NO;
        confirmButton.enabled = NO;
    } else { // Friends
        self.tableView.allowsMultipleSelection = YES;
        confirmButton.enabled = YES;
        [selectedUsers removeAllObjects];
    }

}

- (void)confirmButtonPressed:(id)sender {
    if (selectedUsers.count < 1) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Choose a friend" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [av show];
    } else {
        PFObject *currTribe = self.tribe;
        PFACL *tribeACL = currTribe.ACL;
        
        PFRelation *members = [currTribe relationForKey:kVYBTribeMembersKey];
        for (PFUser *newMember in selectedUsers) {
            [members addObject:newMember];
            [tribeACL setReadAccess:YES forUser:newMember];
            [tribeACL setWriteAccess:YES forUser:newMember];
        }
        currTribe.ACL = tribeACL;
        [currTribe saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                NSLog(@"Members added");
                [self.navigationController popViewControllerAnimated:NO];
            } else {
                NSString *msg = [NSString stringWithFormat:@"Network problem occured"];
                UIAlertView *popUp = [[UIAlertView alloc] initWithTitle:@"" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [popUp show];
            }
        }];
    }
}

- (void)inviteFriend:(id)sender {
    VYBInviteViewController *inviteVC = [[VYBInviteViewController alloc] init];
    [self.navigationController pushViewController:inviteVC animated:NO];
}

- (void)shouldToggleFollowFriendForCell:(VYBFriendCell *)aCell {
    PFUser *cellUser = aCell.user;
    if ([aCell.followButton isSelected]) {
        // Unfollow
        aCell.followButton.selected = NO;
        [VYBUtility unfollowUserEventually:cellUser];
        //[[NSNotificationCenter defaultCenter] postNotificationName:PAPUtilityUserFollowingChangedNotification object:nil];
    } else {
        // Follow
        aCell.followButton.selected = YES;
        [VYBUtility followUserInBackground:cellUser block:^(BOOL succeed, NSError *err) {
            if (!err) {
                //[[NSNotificationCenter defaultCenter] postNotificationName:PAPUtilityUserFollowingChangedNotification object:nil];
            } else {
                aCell.followButton.selected = NO;
            }
        }];
    }
}

#pragma mark - UIDeviceOrientation
- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}



@end
