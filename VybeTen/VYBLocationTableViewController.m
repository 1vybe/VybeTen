//
//  VYBLocationTableViewController.m
//  VybeTen
//
//  Created by jinsuk on 8/27/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBLocationTableViewController.h"
#import "VYBAppDelegate.h"
#import "VYBLocationTableViewCell.h"
#import "VYBPlayerViewController.h"
#import "VYBProfileViewController.h"

@interface VYBLocationTableViewController ()
@property (nonatomic, strong) NSArray *regions;
@property (nonatomic, strong) NSDictionary *vybeByLocation;
@property (nonatomic, strong) NSDictionary *userByLocation;
@end

@implementation VYBLocationTableViewController {
}


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
    
    [self getUserCountByLocation];
    [self parseVybesToSections];
}

- (void)getUserCountByLocation {
    PFQuery *query = [PFUser query];
    // 24 TTL checking
    NSDate *someTimeAgo = [[NSDate alloc] initWithTimeIntervalSinceNow:-3600 * VYBE_TTL_HOURS];
    [query whereKey:kVYBUserLastVybedTimeKey greaterThanOrEqualTo:someTimeAgo];
    [query whereKey:kVYBUserUsernameKey notEqualTo:[PFUser currentUser][kVYBUserUsernameKey]];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
            for (PFObject *aUser in objects) {
                NSArray *token = [aUser[kVYBUserLastVybedLocationKey] componentsSeparatedByString:@","];
                if (token.count != 3)
                    continue;
                
                //NOTE: we discard the first location field (neighborhood)
                NSString *keyString = [NSString stringWithFormat:@"%@,%@", token[1], token[2]];
                if ([newDict objectForKey:keyString]) {
                    NSNumber *newCount = newDict[keyString] + 1;
                    [newDict set forKey:keyString];
                } else {
                    
                }
            }
        }
    }];
}

- (void)parseVybesToSections {
    NSMutableDictionary *aDict = [[NSMutableDictionary alloc] init];
    for (PFObject *obj in self.objects) {
        NSString *locString = obj[kVYBVybeLocationStringKey];
        NSArray *token = [locString componentsSeparatedByString:@","];
        if (token.count != 3)
            continue;
        
        //NOTE: we discard the first location field (neighborhood)
        NSString *keyString = [NSString stringWithFormat:@"%@,%@", token[1], token[2]];
        if ([aDict objectForKey:keyString]) {
            NSMutableArray *arr = (NSMutableArray *)aDict[keyString];
            [arr addObject:obj];
        } else {
            NSMutableArray *newArr = [[NSMutableArray alloc] init];
            [newArr addObject:obj];
            [aDict setObject:newArr forKey:keyString];
        }
    }
    self.vybeByLocation = [NSDictionary dictionaryWithDictionary:aDict];
    [self.tableView reloadData];
}


#pragma mark - UITableViewController

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.vybeByLocation)
        return 0;
    
    return self.vybeByLocation.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *LocationTableCellIdentifier = @"LocationTableCellIdentifier";

    VYBLocationTableViewCell *cell = (VYBLocationTableViewCell *)[tableView dequeueReusableCellWithIdentifier:LocationTableCellIdentifier];

    NSString *locationStr = self.vybeByLocation.allKeys[indexPath.row];

    [cell setLocationString:locationStr];
    [cell setVybeCount:[self.vybeByLocation[locationStr] count]];
    
    //[cell.unwatchedVybeButton setContentMode:UIViewContentModeScaleAspectFit];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *locationKey = self.vybeByLocation.allKeys[indexPath.section];
    NSArray *users = self.vybeByLocation[locationKey];
    PFUser *aUser = users[indexPath.row];
    
    VYBProfileViewController *profileVC = [[VYBProfileViewController alloc] init];
    [profileVC setUser:aUser];
    
    [self.navigationController pushViewController:profileVC animated:NO];
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
