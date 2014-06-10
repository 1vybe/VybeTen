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
    
    UIButton *confirmButton;
    UIButton *cancelButton;
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
        
        self.paginationEnabled = YES;
        
        self.objectsPerPage = 20;
        
        membersTabSelected = YES;
        
        self.tableView.allowsMultipleSelection = NO;
        
        self.tableView.allowsSelection = NO;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Adding a dark TOPBAR
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.height - 50, 50);
    topBar = [[UIView alloc] initWithFrame:frame];
    [topBar setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.1]];
    [self.view addSubview:topBar];
   
    /*
    // Adding Label
    frame = CGRectMake(0, 0, 200, 50);
    screenTitleLabel = [[UILabel alloc] initWithFrame:frame];
    [screenTitleLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20.0]];
    [screenTitleLabel setTextColor:[UIColor whiteColor]];
    [screenTitleLabel setText:@"M E M B E R S"];
    [topBar addSubview:screenTitleLabel];

    // Adding Invite friends button
    frame = CGRectMake(self.view.bounds.size.width - 150, 0, 50, 50);
    inviteButton = [[UILabel alloc] initWithFrame:frame];
    [inviteButton setText:@"+"];
    [inviteButton setTextColor:[UIColor whiteColor]];
    [inviteButton setTextAlignment:NSTextAlignmentCenter];
    [inviteButton setFont:[UIFont fontWithName:@"Montreal-Xlight" size:40]];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addFriend:)];
    [inviteButton addGestureRecognizer:tap];
    [inviteButton setUserInteractionEnabled:YES];
    [topBar addSubview:inviteButton];
    */
    
    // Adding CONFIRM button
    frame = CGRectMake(self.view.bounds.size.width - 50, 0, 50, 50);
    confirmButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *confimImg = [UIImage imageNamed:@"button_check.png"];
    [confirmButton setImage:confimImg forState:UIControlStateNormal];
    [confirmButton addTarget:self action:@selector(didTapConfirmButton:) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:confirmButton];
    // Adding a tab button
    frame = CGRectMake(50, 0, 50, 50);
    alreadyMembersTabButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *alreadyMembersImg = [UIImage imageNamed:@"button_friends.png"];
    [alreadyMembersTabButton setImage:alreadyMembersImg forState:UIControlStateNormal];
    [alreadyMembersTabButton addTarget:self action:@selector(alreadyMembersTabSelected:) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:alreadyMembersTabButton];
    // Adding another tab button
    frame = CGRectMake(100, 0, 50, 50);
    nonMembersTabButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *nonMembersImg = [UIImage imageNamed:@"button_featured.png"];
    [nonMembersTabButton setImage:nonMembersImg forState:UIControlStateNormal];
    [nonMembersTabButton addTarget:self action:@selector(nonMembersTabSelected:) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:nonMembersTabButton];
    // Adding CANCEL button
    frame = CGRectMake(0, 0, 50, 50);
    cancelButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *cancelImg = [UIImage imageNamed:@"button_cancel.png"];
    [cancelButton setImage:cancelImg forState:UIControlStateNormal];
    //[captureButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [cancelButton addTarget:self action:@selector(didTapCancelButton:) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:cancelButton];
    
    
    // By default we show members only first
    confirmButton.hidden = YES;
    cancelButton.hidden = YES;
}

#pragma mark - PFQueryTableView

- (PFQuery *)queryForTable {
    if (membersTabSelected) {
        return [self queryForMembers];
    }
    else {
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

- (void)alreadyMembersTabSelected:(id)sender {
    membersTabSelected = YES;
    
    self.tableView.allowsMultipleSelection = NO;
    
    [nonMembersTabButton setSelected:NO];
    
    confirmButton.hidden = YES;
    cancelButton.hidden = YES;
    
    [self loadObjects];
}

- (void)nonMembersTabSelected:(id)sender {
    membersTabSelected = NO;
    self.tableView.allowsMultipleSelection = YES;
    
    [alreadyMembersTabButton setSelected:NO];

    [selectedUsers removeAllObjects];
    
    confirmButton.hidden = NO;
    cancelButton.hidden = NO;
    
    [self loadObjects];
}


- (void)didTapBackButton:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)didTapConfirmButton:(id)sender {
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

- (void)didTapCancelButton:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
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

/*
- (BOOL)isAlreadyMember:(PFUser *)aUser {
    for (PFUser *member in alreadyMembers) {
        if ([member.objectId isEqual:aUser.objectId]) {
            return YES;
        }
    }
    return NO;
}
*/

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}



@end
