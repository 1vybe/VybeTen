//
//  VYBTribeVybesViewController.m
//  VybeTen
//
//  TODO: Notification. Refresh Cell.
//  BUGS: LoadMore cell should not be displayed when the number of all objects is less than the number of objects per page
//
//  Created by jinsuk on 3/20/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBTribeTimelineViewController.h"
#import "VYBPlayerViewController.h"
#import "VYBMenuViewController.h"
#import "VYBAddMemberViewController.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"
#import "VYBUtility.h"


@implementation VYBTribeTimelineViewController {
   
    UILabel *countLabel;
    UIButton *membersButton;
    UIView *topBar;
    
    VYBPlayerViewController *playerVC;

    /*
    UIButton *menuButton;
    UIButton *buttonCapture;
    UIButton *buttonBack;
    */
}

@synthesize tribe;

#pragma mark - Initialization

- (void)dealloc {

}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // The className to query on
        self.parseClassName = kVYBVybeClassKey;
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = YES;
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
        // The number of objects to show per page
        self.objectsPerPage = 15;
    }
    
    return self;
}


#pragma mark - UIViewController

- (void)viewDidLoad
{
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    [super viewDidLoad];
    
    self.tableView.showsVerticalScrollIndicator = NO;
    
    // Add blurredView
    UIToolbar* blurredView = [[UIToolbar alloc] initWithFrame:self.tableView.bounds];
    [blurredView setBarStyle:UIBarStyleDefault];
    [self.tableView setBackgroundView:blurredView];
    
    
    // Adding a dark TOPBAR
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.height - 50, 50);
    topBar = [[UIView alloc] initWithFrame:frame];
    [topBar setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.1]];
    [self.view addSubview:topBar];
    
    // Adding COUNT label
    // These frequent view related steps should be done in Model side.
    // Count label translates the view by 35 px along x and 85px along y axis because the label is a rectangle
    frame = CGRectMake(0, 0, 150, 50);
    countLabel = [[UILabel alloc] initWithFrame:frame];
    [countLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20]];
    [countLabel setText:[NSString stringWithFormat:@"%@", [self.tribe objectForKey:kVYBTribeNameKey]]];
    [countLabel setTextColor:[UIColor whiteColor]];
    [countLabel setTextAlignment:NSTextAlignmentLeft];
    [countLabel setBackgroundColor:[UIColor clearColor]];
    [self.tableView addSubview:countLabel];
   
    // Adding FRIENDS button
    frame = CGRectMake(self.view.bounds.size.width - 50, 0, 50, 50);
    membersButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *friendsImg = [UIImage imageNamed:@"button_friends.png"];
    [membersButton setContentMode:UIViewContentModeCenter];
    [membersButton setImage:friendsImg forState:UIControlStateNormal];
    [membersButton addTarget:self action:@selector(didTapOnMembersButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.tableView addSubview:membersButton];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
}

#pragma mark - PFQueryTableViewController

- (PFQuery *)queryForTable {
    if (![PFUser currentUser]) {
        PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
        [query setLimit:0];
        return query;
    }
    
    PFQuery *query = [PFQuery queryWithClassName:kVYBVybeClassKey];
    [query whereKey:kVYBVybeTribeKey equalTo:self.tribe];
    // A pull-to-refresh should always trigger a network request.
    [query setCachePolicy:kPFCachePolicyNetworkOnly];
    [query orderByDescending:kVYBVybeTimestampKey];
    [query setLimit:1000];
    [query includeKey:kVYBVybeUserKey];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    //
    // If there is no network connection, we will hit the cache first.
    /*
    if (self.objects.count == 0 || ![[UIApplication sharedApplication].delegate performSelector:@selector(isParseReachable)]) {
        [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
    }
    */
    /*
     This query will result in an error if the schema hasn't been set beforehand. While Parse usually handles this automatically, this is not the case for a compound query such as this one. The error thrown is:
     
     Error: bad special key: __type
     
     To set up your schema, you may post a photo with a caption. This will automatically set up the Photo and Activity classes needed by this query.
     
     You may also use the Data Browser at Parse.com to set up your classes in the following manner.
     
     Create a User class: "User" (if it does not exist)
     
     Create a Custom class: "Activity"
     - Add a column of type pointer to "User", named "fromUser"
     - Add a column of type pointer to "User", named "toUser"
     - Add a string column "type"
     
     Create a Custom class: "Photo"
     - Add a column of type pointer to "User", named "user"
     
     You'll notice that these correspond to each of the fields used by the preceding query.
     */
    
    return query;
}

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    NSLog(@"New number of objects: %lui", self.objects.count);
}

#pragma mark - UITableViewController

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *VybeCellIdentifier = @"VybeCellIdentifier";
    
    VYBVybeCell *cell = [tableView dequeueReusableCellWithIdentifier:VybeCellIdentifier];
    
    if (!cell) {
        cell = [[VYBVybeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:VybeCellIdentifier];
        cell.delegate = self;
    }
    
    [cell setVybe:object];
    
    return cell;
}


/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *LoadMoreCellIdentifier = @"LoadMoreCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:LoadMoreCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LoadMoreCellIdentifier];
        cell.selectionStyle =UITableViewCellSelectionStyleGray;
        //cell.separatorImageTop.image = [UIImage imageNamed:@"SeparatorTimelineDark.png"];
        //cell.hideSeparatorBottom = YES;
        //cell.mainView.backgroundColor = [UIColor clearColor];
        [cell setBackgroundColor:[UIColor orangeColor]];
    }
    return cell;
}
*/

/*
 - (PFObject *)objectAtIndexPath:(NSIndexPath *)indexPath {
 if (indexPath.row < self.objects.count) {
 return [self.objects objectAtIndex:indexPath.row];
 }
 
 return nil;
 }
 */

#pragma mark - UITableViewCellDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.objects.count) {
        return [VYBVybeCell heightForCell];
    } else {
        return 44.0f;
    }
}

#pragma mark - VYBVybeCellDelegate

- (void)cell:(VYBVybeCell *)cellView didTapVybeButton:(PFObject *)aVybe {
    playerVC = [[VYBPlayerViewController alloc] init];
    [playerVC setVybePlaylist:self.objects];
}

#pragma mark - ()

- (void)didTapOnMembersButton:(id)sender {
    VYBAddMemberViewController *addMemberVC = [[VYBAddMemberViewController alloc] initWithTribe:self.tribe];
    [self.navigationController pushViewController:addMemberVC animated:NO];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
