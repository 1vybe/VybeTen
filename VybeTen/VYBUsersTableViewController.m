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
#import "VYBCache.h"

@interface VYBUsersTableViewController ()

@end

@implementation VYBUsersTableViewController {
    NSArray *users;
    UIImageView *countryFlagImageView;
}

- (void)loadView {
    [super loadView];
    users = [[VYBCache sharedCache] usersForLocation:self.locationKey];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [countryFlagImageView removeFromSuperview];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    
    NSString *cityName = [self.locationKey componentsSeparatedByString:@","][0];
    self.navigationItem.title = cityName;
    
    NSString *countryCode = [self.locationKey componentsSeparatedByString:@","][1];
    // NOTE: This assumes that the navigation bar height is 44pt
    countryFlagImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 40 - 10, 2, 40, 40)];
    [countryFlagImageView setImage:[UIImage imageNamed:countryCode]];
    [self.navigationController.navigationBar addSubview:countryFlagImageView];
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
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject *aUser = users[indexPath.row];
    VYBProfileViewController *profileVC = [[VYBProfileViewController alloc] init];
    [profileVC setUser:aUser];
    [self.navigationController pushViewController:profileVC animated:NO];
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
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
