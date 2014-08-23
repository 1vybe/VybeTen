//
//  VYBHubViewController.m
//  VybeTen
//
//  Created by jinsuk on 8/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBHubViewController.h"
#import "VYBAppDelegate.h"
#import "VYBFriendTableViewCell.h"
#import "VYBRegionHeaderButton.h"
#import "VYBPlayerViewController.h"
#import "VYBFriendsViewController.h"
#import "VYBProfileViewController.h"

@interface VYBHubViewController ()
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISearchDisplayController *searchDisplay;
@property (nonatomic, strong) NSArray *regions;
@property (nonatomic, strong) NSDictionary *sections;
@end

@implementation VYBHubViewController {
    NSInteger selectedSection;
    VYBRegionHeaderButton *selectedHeaderButton;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    selectedSection = -1;
    
    self.navigationItem.hidesBackButton = YES;
    
    UIBarButtonItem *captureButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_capture.png"] style:UIBarButtonItemStylePlain target:self action:@selector(captureButtonPressed:)];
    UIBarButtonItem *playAllButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(allButtonItemPressed:)];
    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchButtonPressed:)];
    self.navigationItem.rightBarButtonItems = @[captureButton, playAllButton];
    
    self.searchBar = [[UISearchBar alloc] init];
    [self.searchBar sizeToFit];
    [self.view addSubview:self.searchBar];
    self.searchBar.hidden = YES;
    //self.tableView.tableHeaderView = self.searchBar;
    
    self.searchDisplay = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
        
    self.navigationController.navigationBarHidden = NO;
    
    NSString *functionName = @"get_regions";
    
    /*
    [PFCloud callFunctionInBackground:functionName withParameters:@{} block:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.regions = objects;
            NSLog(@"there are %d regions", self.regions.count);
            [self.tableView reloadData];
        } else {
            NSLog(@"get_regions failed: %@", error);
        }
    }];
    */
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = YES;
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
    
    headerButton.regionNameLabel.text = location;
    
    NSArray *arr = self.sections[location];
    headerButton.regionUserCountLabel.text = [NSString stringWithFormat:@"%d", (int)arr.count];
    
    headerButton.sectionNumber = section;
    [headerButton addTarget:self action:@selector(headerButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    return headerButton;
}

/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSArray *location = self.sections.allKeys[section];
    NSArray *arr = self.sections[location];

    return [NSString stringWithFormat:@"%@  [%d]", location, (int)arr.count];
}
*/

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

/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}
*/

- (void)allButtonItemPressed:(id)sender {
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
    [self.navigationController pushViewController:playerVC animated:NO];
}

- (void)searchButtonPressed:(id)sender {
    self.searchBar.hidden = NO;
    [self.searchBar becomeFirstResponder];
}

- (void)captureButtonPressed:(id)sender {
    VYBAppDelegate *appDel = (VYBAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDel moveToPage:VYBCapturePageIndex];
}


- (void)headerButtonPressed:(VYBRegionHeaderButton *)sender {
    if (selectedSection == sender.sectionNumber) {
        selectedSection = -1;
    } else {
        selectedSection = sender.sectionNumber;
    }
    
    [self.tableView reloadData];
}

#pragma mark - DeviceOrientation

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
