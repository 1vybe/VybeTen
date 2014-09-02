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
@property (nonatomic, strong) NSArray *regions;

//@property (nonatomic, strong) NSDictionary *vybeByLocation;
//@property (nonatomic, strong) NSDictionary *userByLocation;
@end

@implementation VYBLocationTableViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // To remove empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}



#pragma mark - PFQueryTableViewController

- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:kVYBVybeClassKey];
    // 24 TTL checking
    NSDate *someTimeAgo = [[NSDate alloc] initWithTimeIntervalSinceNow:-3600 * VYBE_TTL_HOURS];
    [query whereKey:kVYBVybeTimestampKey greaterThanOrEqualTo:someTimeAgo];
    // Don't include urself
    [query whereKey:kVYBVybeUserKey notEqualTo:[PFUser currentUser]];
    [query whereKeyExists:kVYBVybeLocationStringKey];
    [query whereKey:kVYBVybeLocationStringKey notEqualTo:@""];
    
    return query;
}

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    
    [[VYBCache sharedCache] clearUsersByLocation];
    [[VYBCache sharedCache] clearVybesByLocation];
    [self getUsersByLocation];
    [self parseVybesToSections];
}

- (void)getUsersByLocation {
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
        }
    }];
}

- (void)parseVybesToSections {
    for (PFObject *obj in self.objects) {
        NSString *locString = obj[kVYBVybeLocationStringKey];
        NSArray *token = [locString componentsSeparatedByString:@","];
        if (token.count != 3)
            continue;
        
        //NOTE: we discard the first location field (neighborhood)
        NSString *keyString = [NSString stringWithFormat:@"%@,%@", token[1], token[2]];
        [[VYBCache sharedCache] addVybe:obj forLocation:keyString];
    }

    [self.tableView reloadData];
}


#pragma mark - UITableViewController

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [[VYBCache sharedCache] numberOfLocations];

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *LocationTableCellIdentifier = @"LocationTableCellIdentifier";

    VYBLocationTableViewCell *cell = (VYBLocationTableViewCell *)[tableView dequeueReusableCellWithIdentifier:LocationTableCellIdentifier];

    NSString *locationKey = [[[VYBCache sharedCache] vybesByLocation] allKeys][indexPath.row];

    [cell setLocationKey:locationKey];
    
    //[cell.unwatchedVybeButton setContentMode:UIViewContentModeScaleAspectFit];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *locationKey = [[[VYBCache sharedCache] vybesByLocation] allKeys][indexPath.row];
    
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

- (void)watchAll {
    
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
