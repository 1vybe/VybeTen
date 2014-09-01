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

@interface VYBFollowingTableViewController ()
- (IBAction)watchAllButtonPressed:(id)sender;
@end

@implementation VYBFollowingTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - UITableViewController

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *UserTableViewCellIdentifier = @"UserTableViewCellIdentifier";
    VYBUserTableViewCell *cell = (VYBUserTableViewCell *)[tableView dequeueReusableCellWithIdentifier:UserTableViewCellIdentifier];
    if (!cell) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"VYBUserTableViewCell" owner:nil options:nil];
        cell = [nib lastObject];
        //NOTE: reuseIdentifier is set in xib file
    }

    NSString *lowerUsername = [(NSString *)object[kVYBUserUsernameKey] lowercaseString];
    
    // TODO: user PFImageView of PFTableViewCell
    [cell.nameLabel setText:lowerUsername];
    
    PFFile *profile = object[kVYBUserProfilePicMediumKey];
    [profile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
            UIImage *profileImg = [UIImage imageWithData:data];
            cell.profileImageView.image = profileImg;
        }
    }];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject *aUser = self.objects[indexPath.row];
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

#pragma amrk - ()

- (void)watchAll {
    
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
