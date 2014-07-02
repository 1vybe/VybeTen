//
//  VYBTribesViewController.m
//  VybeTen
//
//  Created by jinsuk on 4/14/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBTribesViewController.h"
#import "VYBMenuViewController.h"
#import "VYBPlayerViewController.h"
#import "VYBTribeTimelineViewController.h"
#import "VYBActivityViewController.h"
#import "VYBConstants.h"
#import "VYBCache.h"

@implementation VYBTribesViewController {
    UIView *topBar;
    UILabel *currentTabLabel;
    UILabel *createButton;
    UISegmentedControl *segmentedControl;
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.paginationEnabled = NO;
        
        self.parseClassName = kVYBTribeClassKey;
        
        self.pullToRefreshEnabled = YES;
    }
    
    return self;
}

- (void)loadView {
    [super loadView];
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_tribes_create.png"] style:UIBarButtonItemStylePlain target:self action:@selector(createButtonPressed:)];
    self.navigationItem.leftBarButtonItem.tintColor = [UIColor grayColor];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_tribes_activity_hollow.png"] style:UIBarButtonItemStylePlain target:self action:@selector(activityButtonPressed:)];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor grayColor];
    //self.navigationItem.rightBarButtonItem.enabled = NO;
    
    segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Following", @"My Tribes"]];
    segmentedControl.selectedSegmentIndex = 0;
    [segmentedControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = segmentedControl;
    self.navigationItem.titleView.tintColor = [UIColor grayColor];

}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = [UIColor clearColor];
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self loadObjects];
}
*/

#pragma mark - PFQueryTableView

- (PFQuery *)queryForTable {
    // User data is not fetched yet from Home screen
    if (![PFUser currentUser]) {
        return nil;
    }
    
    PFQuery *query = [PFQuery queryWithClassName:kVYBTribeClassKey];
    [query includeKey:kVYBTribeNewestVybeKey];
    NSInteger idx = segmentedControl.selectedSegmentIndex;
    // Following Segment
    if (idx == 0) {
        PFQuery *following = [PFQuery queryWithClassName:kVYBActivityClassKey];
        [following whereKey:kVYBActivityTypeKey equalTo:kVYBActivityTypeFollow];
        [following whereKey:kVYBActivityFromUserKey equalTo:[PFUser currentUser]];
    
        [query whereKey:kVYBTribeCreatorKey matchesKey:kVYBActivityToUserKey inQuery:following];
        [query whereKey:kVYBTribeMembersKey notEqualTo:[PFUser currentUser]];
    }
    // My Tribes Segment
    else {
        [query whereKey:kVYBTribeMembersKey equalTo:[PFUser currentUser]];
    }
    
    if (self.objects.count == 0) {
        //contributingQuery.cachePolicy = kPFCachePolicyCacheElseNetwork;
    }
    
    [query orderByAscending:kVYBTribeNameKey];
    
    return query;
}


- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *TribeCellIdentifier = @"TribeCellIdentifier";
    
    VYBTribeCell *cell = [tableView dequeueReusableCellWithIdentifier:TribeCellIdentifier];
    
    if (!cell) {
        cell = [[VYBTribeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TribeCellIdentifier];
        cell.delegate = self;
    }
    
    [cell setTribe:object];
    
    return cell;
}


#pragma mark - VYBTribeCellDelegate

- (void)cell:(VYBTribeCell *)cellView didTapTribeButton:(PFObject *)aTribe {
    VYBTribeTimelineViewController *tribeTimeline = [[VYBTribeTimelineViewController alloc] init];
    [tribeTimeline setTribe:aTribe];
    [self.navigationController pushViewController:tribeTimeline animated:NO];
}

- (void)cell:(VYBTribeCell *)cellView didTapVybeButton:(PFObject *)aVybe {
    
}

#pragma mark - UITableViewCellDelegate

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [VYBTribeCell heightForCell];
}

#pragma mark - VYBCreateTribeViewControllerDelegate

- (void)createdTribe:(PFObject *)aTribe {
    [self loadObjects];
    VYBTribeTimelineViewController *tribeTimeline = [[VYBTribeTimelineViewController alloc] init];
    [tribeTimeline setTribe:aTribe];
    [self.navigationController pushViewController:tribeTimeline animated:NO];
}


#pragma mark - UIDeviceOrientation
- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - ()

- (void)activityButtonPressed:(id)sender {
    VYBActivityViewController *activityVC = [[VYBActivityViewController alloc] init];
    [self.navigationController pushViewController:activityVC animated:NO];
}

- (void)captureVybe:(id)sender {
    //[self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)segmentChanged:(id)sender {
    [self loadObjects];
}


- (void)createButtonPressed:(id)sender {
    VYBCreateTribeViewController *createTribeVC = [[VYBCreateTribeViewController alloc] init];
    createTribeVC.delegate = self;
    [self.navigationController presentViewController:createTribeVC animated:YES completion:nil];
}




@end
