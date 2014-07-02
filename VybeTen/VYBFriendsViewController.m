//
//  VYBFriendsViewController.m
//  VybeTen
//
//  Created by jinsuk on 4/25/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBFriendsViewController.h"
#import "VYBMenuViewController.h"
#import "VYBInviteViewController.h"
#import "VYBCache.h"
#import "VYBUtility.h"
#import "MBProgressHUD.h"
#import "VYBFriendCell.h"

@implementation VYBFriendsViewController {
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        
        self.paginationEnabled = NO;
        
        self.pullToRefreshEnabled = YES;
                
        //self.tableView.allowsSelection = NO;
    }
    
    return self;
}


- (void)loadView {
    [super loadView];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_friends_profile.png"] style:UIBarButtonItemStylePlain target:self action:@selector(profileButtonPressed:)];
    self.navigationItem.leftBarButtonItem.tintColor = [UIColor grayColor];
    self.navigationItem.leftBarButtonItem.enabled = NO;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_friends_add.png"] style:UIBarButtonItemStylePlain target:self action:@selector(addButtonPressed:)];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor grayColor];
    //self.navigationItem.rightBarButtonItem.enabled = NO;

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = [UIColor clearColor];

}

#pragma mark - PFQueryTableViewController

- (PFQuery *)queryForTable {
    // User data is not fetched yet from Home screen
    if (![PFUser currentUser]) {
        return nil;
    }
    
    PFQuery *query = [PFUser query];
    
    // PFQuery for retrieving a list of friends on Vybe
    NSArray *facebookFriends = [[VYBCache sharedCache] facebookFriends];
    [query whereKey:kVYBUserFacebookIDKey containedIn:facebookFriends];
    
    if (self.objects.count == 0) {
        query.cachePolicy = kPFCachePolicyCacheElseNetwork;
    }
    [query orderByAscending:kVYBUserDisplayNameKey];
    
    return query;
}

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    
    // Refresh follow status for friends
    PFQuery *isFollowedByCurrentUser = [PFQuery queryWithClassName:kVYBActivityClassKey];
    [isFollowedByCurrentUser whereKey:kVYBActivityFromUserKey equalTo:[PFUser currentUser]];
    [isFollowedByCurrentUser whereKey:kVYBActivityToUserKey containedIn:self.objects];
    [isFollowedByCurrentUser whereKey:kVYBActivityTypeKey equalTo:kVYBActivityTypeFollow];
    [isFollowedByCurrentUser setCachePolicy:kPFCachePolicyNetworkOnly];
    [isFollowedByCurrentUser findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (PFObject *following in objects) {
                [[VYBCache sharedCache] setFollowStatus:YES user:following[kVYBActivityToUserKey]];
            }
            [self.tableView reloadData];
        }
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *FriendCellIdentifier = @"FriendCell";
    
    VYBFriendCell *cell = [self.tableView dequeueReusableCellWithIdentifier:FriendCellIdentifier];
    if (!cell) {
        cell = [[VYBFriendCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:FriendCellIdentifier];
        [cell setDelegate:self];
    }
    [cell setUser:(PFUser *)object];
    cell.followButton.selected = [[VYBCache sharedCache] followStatusForUser:(PFUser *)object];
    
    return cell;
}

#pragma mark - ()

- (void)goToMenu:(id)sender {
    VYBMenuViewController *menuVC = [[VYBMenuViewController alloc] init];
    menuVC.view.backgroundColor = [UIColor clearColor];
    menuVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    //[menuVC setTransitioningDelegate:transitionController];
    //menuVC.modalPresentationStyle = UIModalPresentationCurrentContext;
    //self.modalPresentationStyle = UIModalPresentationCurrentContext;
    [self.navigationController presentViewController:menuVC animated:YES completion:nil];
}

- (void)captureVybe:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)addButtonPressed:(id)sender {
    // Display the requests dialog
    [FBWebDialogs
     presentRequestsDialogModallyWithSession:nil
     message:@"Learn how to make your iOS apps social."
     title:nil
     parameters:nil
     handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
         if (error) {
             // Error launching the dialog or sending the request.
             NSLog(@"Error sending request.");
         } else {
             if (result == FBWebDialogResultDialogNotCompleted) {
                 // User clicked the "x" icon
                 NSLog(@"User canceled request.");
             } else {
                 // Handle the send request callback
                 NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                 if (![urlParams valueForKey:@"request"]) {
                     // User clicked the Cancel button
                     NSLog(@"User canceled request.");
                 } else {
                     // User clicked the Send button
                     NSString *requestID = [urlParams valueForKey:@"request"];
                     NSLog(@"Request ID: %@", requestID);
                 }
             }
         }
     }];
}

- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[kv[0]] = val;
    }
    return params;
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



#pragma mark - UITableViewCellDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.objects.count) {
        return [VYBFriendCell heightForCell];
    } else {
        return 44.0f;
    }
}

#pragma makr - VYBFriendsCellDelegate
- (void)cell:(VYBFriendCell *)cellView didTapUserButton:(PFUser *)aUser {
    
}

- (void)cell:(VYBFriendCell *)cellView didTapFollowButton:(PFUser *)aUser {
    [self shouldToggleFollowFriendForCell:cellView];
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
