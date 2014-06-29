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
        
        // Infinite scrolling
        self.paginationEnabled = NO;
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
    }
    
    return self;
}


#pragma mark - UIViewController

- (void)loadView {
    [super loadView];
    
    CGRect frame = CGRectMake(0, 0, 150, 50);
    countLabel = [[UILabel alloc] initWithFrame:frame];
    [countLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20]];
    [countLabel setText:[NSString stringWithFormat:@"%@", [self.tribe objectForKey:kVYBTribeNameKey]]];
    [countLabel setTextColor:[UIColor greenColor]];
    //[countLabel setTextAlignment:NSTextAlignmentLeft];
    //[countLabel setBackgroundColor:[UIColor clearColor]];
    self.navigationItem.titleView = countLabel;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_friends.png"] style:UIBarButtonItemStylePlain target:self action:@selector(membersButtonPressed:)];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor grayColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = [UIColor clearColor];
    
    self.tableView.showsVerticalScrollIndicator = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
 }

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.lastWatchedVybe) {
        [self moveToLastWatchtedVybeCell];
    }
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
    [query includeKey:kVYBVybeTribeKey];
    [query includeKey:kVYBVybeUserKey];
    // A pull-to-refresh should always trigger a network request.
    [query setCachePolicy:kPFCachePolicyNetworkOnly];
    [query orderByDescending:kVYBVybeTimestampKey];
    [query setLimit:1000];
    
    
    return query;
}

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    if (self.lastWatchedVybe) {
        [self moveToLastWatchtedVybeCell];
    }
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
    cell.tag = indexPath.row;
    
    return cell;
}


- (void)moveToLastWatchtedVybeCell {
    if (self.objects.count < 1) {
        return;
    }
    
    NSInteger lastIdx = 0;
    for (NSInteger i = 0; i < self.objects.count; i++) {
        PFObject *obj = self.objects[i];
        if ([obj.objectId isEqualToString:self.lastWatchedVybe.objectId]) {
            lastIdx = i;
            break;
        }
    }
    
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:lastIdx inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    self.lastWatchedVybe = nil;
}


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
    playerVC.parentVC = self;
    [self presentViewController:playerVC animated:YES completion:nil];
    // Reverse vybes so the most recent start at 0 and the oldest at the end. 
    NSArray *reverse = [[self.objects reverseObjectEnumerator] allObjects];
    [playerVC setVybePlaylist:reverse];
    [playerVC beginPlayingFrom:reverse.count - cellView.tag - 1];
}


#pragma mark - ()

- (void)membersButtonPressed:(id)sender {
    VYBAddMemberViewController *addMemberVC = [[VYBAddMemberViewController alloc] initWithTribe:self.tribe];
    [self.navigationController pushViewController:addMemberVC animated:NO];
}

- (void)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
