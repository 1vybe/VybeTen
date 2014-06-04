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
    UIButton *buttonCapture;
    UIButton *buttonBack;
    UILabel *countLabel;
    
    UIView *topBar;
    UIButton *menuButton;    
    UIButton *friendsButton;
    
    UILabel *centerCellLabel;
}

@synthesize currTribe = _currTribe;

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
        self.objectsPerPage = 7;
    }
    
    return self;
}


#pragma mark - UIViewController

- (void)viewDidLoad
{
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    [super viewDidLoad];
    
    self.tableView.frame = CGRectMake(0, 0, self.tableView.frame.size.width, self.tableView.frame.size.height);
    // Rotate the tableView clockwise for horizontal scrolling
    CGAffineTransform rotateTable = CGAffineTransformMakeRotation(M_PI_2);
    self.tableView.transform = rotateTable;
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    //[self.tableView setRowHeight:200.0f];
    self.tableView.showsVerticalScrollIndicator = NO;
    // Add blurredView
    UIToolbar* blurredView = [[UIToolbar alloc] initWithFrame:self.tableView.bounds];
    [blurredView setBarStyle:UIBarStyleBlack];
    [self.tableView setBackgroundView:blurredView];
    
    
    // Adding a dark TOPBAR
    CGRect frame = CGRectMake(0, 0, 50, self.view.bounds.size.height);
    topBar = [[UIView alloc] initWithFrame:frame];
    [topBar setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.1]];
    [self.view addSubview:topBar];
    
    // Adding BACK button
    CGRect buttonBackFrame = CGRectMake(0, self.view.bounds.size.height - 50, 50, 50);
    buttonBack = [[UIButton alloc] initWithFrame:buttonBackFrame];
    UIImage *backImage = [UIImage imageNamed:@"button_back.png"];
    [buttonBack setContentMode:UIViewContentModeCenter];
    [buttonBack setImage:backImage forState:UIControlStateNormal];
    CGAffineTransform counterClockwise = CGAffineTransformMakeRotation(-M_PI_2);
    buttonBack.transform = counterClockwise;
    [buttonBack addTarget:self action:@selector(goBack:) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:buttonBack];
    // Adding MENU button
    frame = CGRectMake(0, 0, 50, 50);
    menuButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *menuImg = [UIImage imageNamed:@"button_menu.png"];
    [menuButton setImage:menuImg forState:UIControlStateNormal];
    menuButton.transform = counterClockwise;
    //[menuButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [menuButton addTarget:self action:@selector(goToMenu:) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:menuButton];
    // Adding COUNT label
    // These frequent view related steps should be done in Model side.
    // Count label translates the view by 35 px along x and 85px along y axis because the label is a rectangle
    frame = CGRectMake(0, 0, 120, 50);
    countLabel = [[UILabel alloc] initWithFrame:frame];
    [countLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20]];
    [countLabel setText:[NSString stringWithFormat:@"%@", [self.currTribe objectForKey:kVYBTribeNameKey]]];
    [countLabel setTextColor:[UIColor whiteColor]];
    [countLabel setTextAlignment:NSTextAlignmentCenter];
    countLabel.transform = counterClockwise;
    [countLabel setBackgroundColor:[UIColor clearColor]];
    [self.tableView addSubview:countLabel];
    countLabel.center = topBar.center;
    
    // Adding CAPTURE button
    CGRect buttonCaptureFrame = CGRectMake(self.view.bounds.size.width - 50, 0, 50, 50);
    buttonCapture = [[UIButton alloc] initWithFrame:buttonCaptureFrame];
    UIImage *captureImage = [UIImage imageNamed:@"button_vybe.png"];
    [buttonCapture setContentMode:UIViewContentModeCenter];
    [buttonCapture setImage:captureImage forState:UIControlStateNormal];
    buttonCapture.transform = counterClockwise;
    [buttonCapture addTarget:self action:@selector(captureVybe:) forControlEvents:UIControlEventTouchUpInside];
    [[self tableView] addSubview:buttonCapture];
   
    // Adding FRIENDS button
    frame = CGRectMake(self.view.bounds.size.width - 50, self.view.bounds.size.height - 50, 50, 50);
    friendsButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *friendsImg = [UIImage imageNamed:@"button_friends.png"];
    [friendsButton setContentMode:UIViewContentModeCenter];
    [friendsButton setImage:friendsImg forState:UIControlStateNormal];
    [friendsButton addTarget:self action:@selector(didTapOnFriendsButton:) forControlEvents:UIControlEventTouchUpInside];
    friendsButton.transform = counterClockwise;
    [self.tableView addSubview:friendsButton];
    
    // Adding Center label
    frame = CGRectMake(self.view.bounds.size.width - 115, (self.view.bounds.size.height - 50)/2 , 180, 50);
    centerCellLabel = [[UILabel alloc] initWithFrame:frame];
    [centerCellLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:18.0f]];
    [centerCellLabel setTextColor:[UIColor whiteColor]];
    [centerCellLabel setTextAlignment:NSTextAlignmentCenter];
    centerCellLabel.transform = counterClockwise;
    [self.tableView addSubview:centerCellLabel];
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
    [query whereKey:kVYBVybeTribeKey equalTo:self.currTribe];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.objects.count) {
        // Load More Section
        return 50.0f;
    }
    
    return 200.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger num = [self.objects count];
    if (self.paginationEnabled && num != 0)
        num++;
    return num;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object
{
    /*
    if (indexPath.row >= self.objects.count) {
        UITableViewCell *cell = [self tableView:tableView cellForNextPageAtIndexPath:indexPath];
        return cell;
    } else {
        static NSString *VybeCell = @"VybeCell";
        
        VYBVybeCell *cell = (VYBVybeCell *)[tableView dequeueReusableCellWithIdentifier:VybeCell];
        if (!cell) {
            cell = [[VYBVybeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:VybeCell];
        }
        cell.imageView.image = [UIImage imageNamed:@"user_avatar.png"];
        
        if (object) {
            cell.imageView.file = object[kVYBVybeThumbnailKey];
            
            if ([cell.imageView.file isDataAvailable]) {
                [cell.imageView loadInBackground];
            }
        }

        return cell;
    }
     */
    return nil;
}


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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.objects.count && self.paginationEnabled) {
        [self loadNextPage];
    }
    else {
        VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
        [self.navigationController presentViewController:playerVC animated:NO completion:^(){
            //[playerVC setVybePlaylist:[self.currTribe vybes]];
            // Here d indicated the number of downloaded vybes and n is the number of vybes including the ones to be downloaded
            [playerVC playFrom:[indexPath row]];
        }];
   }
}

#pragma mark - ()

- (void)didTapOnFriendsButton:(id)sender {
    VYBAddMemberViewController *addMemberVC = [[VYBAddMemberViewController alloc] init];
    [self.navigationController pushViewController:addMemberVC animated:NO];
    [addMemberVC setCurrTribe:self.currTribe];
}

- (void)captureVybe:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

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

/**
 * Repositioning floating views during/after scroll
 **/
#pragma mark - UIScrollViewDelegate 

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    // if decelerating, let scrollViewDidEndDecelerating: handle it
    if (decelerate == NO) {
        //[self centerTable];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    //[self centerTable];
}

- (void)centerTable {
    NSIndexPath *pathForCenterCell = [self.tableView indexPathForRowAtPoint:CGPointMake(CGRectGetMidX(self.tableView.bounds), CGRectGetMidY(self.tableView.bounds))];
    
    [self.tableView scrollToRowAtIndexPath:pathForCenterCell atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    
    if (pathForCenterCell.row < self.objects.count) {
        PFObject *centerVybe = [self.objects objectAtIndex:pathForCenterCell.row];
        NSDate *centerDate = centerVybe[kVYBVybeTimestampKey];
        [centerCellLabel setText:[VYBUtility localizedDateStringFrom:centerDate]];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect frameTwo = buttonCapture.frame;
    frameTwo.origin.y = scrollView.contentOffset.y;
    buttonCapture.frame = frameTwo;
    
    CGRect frameThree = topBar.frame;
    frameThree.origin.y = scrollView.contentOffset.y;
    topBar.frame = frameThree;
    
    CGRect frameFour = friendsButton.frame;
    frameFour.origin.y = scrollView.contentOffset.y + self.view.bounds.size.height - 50;
    friendsButton.frame = frameFour;
    
    countLabel.center = topBar.center;
    
    CGRect frameFive = centerCellLabel.frame;
    frameFive.origin.y = scrollView.contentOffset.y + (self.view.bounds.size.height - 180)/2;
    centerCellLabel.frame = frameFive;
    
    [[self view] bringSubviewToFront:topBar];
    [[self view] bringSubviewToFront:buttonCapture];
    [[self view] bringSubviewToFront:countLabel];
    [[self view] bringSubviewToFront:friendsButton];
    [[self view] bringSubviewToFront:centerCellLabel];

    // Change the text of CENTER label
    NSIndexPath *pathForCenterCell = [self.tableView indexPathForRowAtPoint:CGPointMake(CGRectGetMidX(self.tableView.bounds), CGRectGetMidY(self.tableView.bounds))];

    if (pathForCenterCell.row < self.objects.count) {
        PFObject *centerVybe = [self.objects objectAtIndex:pathForCenterCell.row];
        NSDate *centerDate = centerVybe[kVYBVybeTimestampKey];
        [centerCellLabel setText:[VYBUtility localizedDateStringFrom:centerDate]];
    }
}
/*
- (NSIndexPath *)indexPathForObject:(PFObject *)targetObject {
    for (int i = 0; i < self.objects.count; i++) {
        PFObject *object = [self.objects objectAtIndex:i];
        if ([[object objectId] isEqualToString:[targetObject objectId]]) {
            return [NSIndexPath indexPathForRow:i inSection:0];
        }
    }
    
    return nil;
}
*/
- (PFObject *)objectAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.objects.count) {
        return [self.objects objectAtIndex:indexPath.row];
    }
    
    return nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
