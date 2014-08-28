//
//  VYBLocationTableViewController.m
//  VybeTen
//
//  Created by jinsuk on 8/27/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBLocationTableViewController.h"
#import "VYBAppDelegate.h"
#import "VYBFriendTableViewCell.h"
#import "VYBRegionHeaderButton.h"
#import "VYBPlayerViewController.h"
#import "VYBProfileViewController.h"

@interface VYBLocationTableViewController ()
@property (nonatomic, strong) NSArray *regions;
@property (nonatomic, strong) NSDictionary *sections;
@end

@implementation VYBLocationTableViewController {
    NSInteger selectedSection;
    VYBRegionHeaderButton *selectedHeaderButton;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    selectedSection = -1;

    
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.allKeys.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (selectedSection < 0) {
        return 0;
    }
    
    if (section == selectedSection) {
        NSArray *keyStr = self.sections.allKeys[section];
        NSArray *arr = self.sections[keyStr];
        return arr.count;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 60.0; // whatever height you want
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    VYBRegionHeaderButton *headerButton = [VYBRegionHeaderButton VYBRegionHeaderButton];
    NSString *location = self.sections.allKeys[section];
    NSArray *array = [location componentsSeparatedByString:@","];
    NSString *cityName;
    NSString *countryCode;
    if (array.count == 3) {
        countryCode = array[2];
        cityName = array[1];
    } else {
        if ([location isEqualToString:@"Seoul"]) {
            countryCode = @"KR";
        }
        if ([location isEqualToString:@"Montréal"]) {
            countryCode = @"CA";
        }
        if ([location isEqualToString:@"Cairo"]) {
            countryCode = @"EG";
        }
    }
    UIImage *flagImg = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png",countryCode]];
    if (flagImg) {
        headerButton.flagImageView.image = flagImg;
    }
    
    NSArray *arr = self.sections[location];
    headerButton.followingCountLabel.text = [NSString stringWithFormat:@"%d Following", (int)arr.count];
    headerButton.cityNameLabel.text = cityName;
    
    headerButton.sectionNumber = section;
    [headerButton addTarget:self action:@selector(headerButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    //[headerButton.unwatchedVybeButton.imageView setImage:[UIImage imageNamed:@"button_circle_blue.png"]];
    [headerButton.unwatchedVybeButton setContentMode:UIViewContentModeScaleAspectFit];
    return headerButton;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *FriendTableViewCellIdentifier = @"FriendTableViewCellIdentifier";
    VYBFriendTableViewCell *cell = (VYBFriendTableViewCell *)[tableView dequeueReusableCellWithIdentifier:FriendTableViewCellIdentifier];
    if (!cell) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"VYBFriendTableViewCell" owner:nil options:nil];
        cell = [nib lastObject];
        //NOTE: reuseIdentifier is set in xib file
    }
    NSString *locationName = self.sections.allKeys[indexPath.section];
    NSArray *users = self.sections[locationName];
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
    NSString *locationKey = self.sections.allKeys[indexPath.section];
    NSArray *users = self.sections[locationKey];
    PFUser *aUser = users[indexPath.row];
    
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
    [query orderByAscending:kVYBUserLastVybedLocationKey];
    
    return query;
}

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    
    [self parseObjectsToSections];
}

- (void)parseObjectsToSections {
    NSMutableDictionary *sectionDict = [[NSMutableDictionary alloc] init];
    for (PFObject *obj in self.objects) {
        NSString *newLocation = obj[kVYBUserLastVybedLocationKey];
        if ([sectionDict objectForKey:newLocation]) {
            NSMutableArray *arr = (NSMutableArray *)sectionDict[newLocation];
            [arr addObject:obj];
        } else {
            NSMutableArray *newArr = [[NSMutableArray alloc] init];
            [newArr addObject:obj];
            [sectionDict setObject:newArr forKey:newLocation];
        }
    }
    self.sections = [NSDictionary dictionaryWithDictionary:sectionDict];
    [self.tableView reloadData];
}



- (void)headerButtonPressed:(VYBRegionHeaderButton *)sender {
    if (selectedSection == sender.sectionNumber) {
        selectedSection = -1;
    } else {
        selectedSection = sender.sectionNumber;
    }
    
    [self.tableView reloadData];
}


/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

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
