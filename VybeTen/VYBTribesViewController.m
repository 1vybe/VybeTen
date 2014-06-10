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
#import "VYBMyTribeStore.h"
#import "VYBTribeTimelineViewController.h"
#import "VYBConstants.h"
#import "VYBCache.h"

@implementation VYBTribesViewController {
    UIView *topBar;
    UILabel *currentTabLabel;
    UILabel *createButton;
    
    //NSInteger _pageIndex;
}
/*
+ (VYBTribesViewController *)tribesViewControllerForPageIndex:(NSInteger)pageIndex {
    if (pageIndex >= 0 ) {
        return [[self alloc] initWithPageIndex:pageIndex];
    }
    return nil;
}

- (id)initWithPageIndex:(NSInteger)pageIndex {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _pageIndex = pageIndex;
    }
    return self;
}

- (NSInteger)pageIndex {
    return _pageIndex;
}

*/

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.paginationEnabled = YES;
        
        self.parseClassName = kVYBTribeClassKey;
        
        self.pullToRefreshEnabled = YES;
        
        self.objectsPerPage = 20;
    }
    
    return self;
}

- (void)loadView {
    [super loadView];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    //TODO: Add observer to NSNotification from AppDelegate for PUSH notification for newly created tribe that this user is invited to
    
    /*
    UIToolbar *backView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.height, self.view.bounds.size.width)];
    [backView setBarStyle:UIBarStyleDefault];
    [self.view addSubview:backView];
    */
    
    // Adding a dark TOPBAR
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, 50);
    topBar = [[UIView alloc] initWithFrame:frame];
    [topBar setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.1]];
    [self.view addSubview:topBar];
    
    // Adding Label
    frame = CGRectMake(0, 0, 150, 50);
    currentTabLabel = [[UILabel alloc] initWithFrame:frame];
    [currentTabLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20.0]];
    [currentTabLabel setTextColor:[UIColor whiteColor]];
    [currentTabLabel setText:@"T R I B E S"];
    [topBar addSubview:currentTabLabel];
    // Adding CREATE button
    frame = CGRectMake(self.view.bounds.size.width - 50, 0, 50, 50);
    createButton = [[UILabel alloc] initWithFrame:frame];
    [createButton setText:@"+"];
    [createButton setTextColor:[UIColor whiteColor]];
    [createButton setTextAlignment:NSTextAlignmentCenter];
    [createButton setFont:[UIFont fontWithName:@"Montreal-Xlight" size:40]];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(createTribe:)];
    [createButton addGestureRecognizer:tap];
    [createButton setUserInteractionEnabled:YES];
    [topBar addSubview:createButton];

}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self loadObjects];
}
*/

#pragma mark - PFQueryTableView

- (PFQuery *)queryForTable {
    PFQuery *contributingQuery = [PFQuery queryWithClassName:kVYBTribeClassKey];
    [contributingQuery whereKey:kVYBTribeMembersKey equalTo:[PFUser currentUser]];
    
    PFQuery *recommendedQuery = [PFQuery queryWithClassName:kVYBTribeClassKey];
    NSArray *followedByMe = [[VYBCache sharedCache] usersFollowedByMe];
    [recommendedQuery whereKey:kVYBTribeMembersKey containedIn:followedByMe];
    
    //PFQuery *query = [PFQuery orQueryWithSubqueries:@[contributingQuery, recommendedQuery]];
    
    if (self.objects.count == 0) {
        contributingQuery.cachePolicy = kPFCachePolicyCacheElseNetwork;
    }
    
    [contributingQuery orderByAscending:kVYBTribeNameKey];
    
    return contributingQuery;
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


#pragma mark - VYBFriendCellDelegate

- (void)cell:(VYBTribeCell *)cellView didTapTribeButton:(PFObject *)aTribe {
    VYBTribeTimelineViewController *tribeTimeline = [[VYBTribeTimelineViewController alloc] init];
    [tribeTimeline setTribe:aTribe];
    [self.navigationController pushViewController:tribeTimeline animated:NO];
}


#pragma mark - UITableViewCellDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.objects.count) {
        return [VYBTribeCell heightForCell];
    } else {
        return 44.0f;
    }
}

#pragma mark - VYBCreateTribeViewControllerDelegate

- (void)createdTribe:(PFObject *)aTribe {
    [self loadObjects];
    VYBTribeTimelineViewController *tribeTimeline = [[VYBTribeTimelineViewController alloc] init];
    [tribeTimeline setTribe:aTribe];
    [self.navigationController pushViewController:tribeTimeline animated:NO];
}

#pragma mark - ()

- (void)goToMenu:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)captureVybe:(id)sender {
    //[self.navigationController popToRootViewControllerAnimated:NO];
}


- (void)createTribe:(id)sender {
    VYBCreateTribeViewController *createTribeVC = [[VYBCreateTribeViewController alloc] init];
    createTribeVC.delegate = self;
    [self.navigationController presentViewController:createTribeVC animated:YES completion:nil];
}


/*
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[[VYBMyTribeStore sharedStore] myTribes] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collection dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];

    PFObject *tribe = [[[VYBMyTribeStore sharedStore] myTribes] objectAtIndex:[indexPath row]];
    
    cell.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    PFImageView *imgView = [[PFImageView alloc] init];
    if (tribe[kVYBTribeThumbnailKey]) {
        [imgView setFile:tribe[kVYBTribeThumbnailKey]];
        [imgView loadInBackground];
    }
    [cell.contentView addSubview:imgView];
    
    NSString *title = [NSString stringWithFormat:@"%d", tribe[kVYBTribeVybeCountKey]];
    
    [self cell:cell setTitle:title tribeName:tribe[kVYBTribeNameKey] indexPath:indexPath];
    return cell;
}

- (void)cell:(UICollectionViewCell *)cell setTitle:(NSString *)title tribeName:(NSString *)name indexPath:(NSIndexPath *)indexPath {
    // Get current cell size
    //CGSize itemSize = [self collectionView:collection layout:flowLayout sizeForItemAtIndexPath:indexPath];
    int top = -30;
    int width;
    if (IS_IPHONE_5)
        width = 150;
    else
        width = 120;
    int height = 80;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, top, width, 30)];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    titleLabel.tag = 77;
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:16]];
    [titleLabel setText:title];
    [self removeReusedLabel:cell tag:77];
    [cell addSubview:titleLabel];
    
    UILabel *tribeNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (height - 30)/2, width, 30)];
    [tribeNameLabel setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.5]];
    tribeNameLabel.tag = 33;
    [tribeNameLabel setTextColor:[UIColor whiteColor]];
    [tribeNameLabel setText:name];
    [tribeNameLabel setTextAlignment:NSTextAlignmentCenter];
    [tribeNameLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:18]];
    [self removeReusedLabel:cell tag:33];
    [cell addSubview:tribeNameLabel];
}

- (void)removeReusedLabel:(UICollectionViewCell *)cell tag:(int)tag {
    UILabel *foundLabelBackground = (UILabel *)[cell viewWithTag:tag];
    if (foundLabelBackground) [foundLabelBackground removeFromSuperview];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    PFObject *tribe = [[[VYBMyTribeStore sharedStore] myTribes] objectAtIndex:[indexPath row]];

    VYBTribeTimelineViewController *tribeTimelineVC = [[VYBTribeTimelineViewController alloc] init];
    [tribeTimelineVC setCurrTribe:tribe];
    [self.navigationController pushViewController:tribeTimelineVC animated:NO];

 
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
    [playerVC setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [self.navigationController presentViewController:playerVC animated:NO completion:^(void) {
        if ([[tribe vybes] count] < 1) {
            [self.navigationController dismissViewControllerAnimated:NO completion:nil];
        } else {
            [playerVC setVybePlaylist:[tribe vybes]];
            [playerVC playFromUnwatched];
        }

        //[vybesVC setCurrTribe:tribe];
        //[self.navigationController pushViewController:vybesVC animated:NO];
    }];
 
}
*/



@end
