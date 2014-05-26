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
#import "VYBImageStore.h"
#import "VYBTribeTimelineViewController.h"
#import "VYBCreateTribeViewController.h"
#import "VYBConstants.h"

@implementation VYBTribesViewController {
    UIView *topBar;
    UILabel *currentTabLabel;
    UILabel *createButton;
    
    UIView *sideBar;
    UIButton *searchButton;
    UIButton *captureButton;
    UIButton *menuButton;
    UIButton *followingButton;
    UIButton *contributingButton;
    UIButton *myTribesButton;
    
    UICollectionView *collection;
    UICollectionViewFlowLayout *flowLayout;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //TODO: Add observer to NSNotification from AppDelegate for PUSH notification for newly created tribe that this user is invited to
    
    UIToolbar *backView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.height, self.view.bounds.size.width)];
    [backView setBarStyle:UIBarStyleBlack];
    [self.view addSubview:backView];
    
    // Adding a dark TOPBAR
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.height - 50, 50);
    topBar = [[UIView alloc] initWithFrame:frame];
    [topBar setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.1]];
    [self.view addSubview:topBar];
    
    // Adding SEARCH button
    frame = CGRectMake(self.view.bounds.size.height - 100, 0, 50, 50);
    searchButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *searchImg = [UIImage imageNamed:@"button_search.png"];
    [searchButton setImage:searchImg forState:UIControlStateNormal];
    //[topBar addSubview:searchButton];
    // Adding Label
    frame = CGRectMake(10, 0, 150, 50);
    currentTabLabel = [[UILabel alloc] initWithFrame:frame];
    [currentTabLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20.0]];
    [currentTabLabel setTextColor:[UIColor whiteColor]];
    [currentTabLabel setText:@"T R I B E S"];
    [topBar addSubview:currentTabLabel];
    // Adding CREATE button
    frame = CGRectMake(self.view.bounds.size.height - 100, 0, 50, 50);
    createButton = [[UILabel alloc] initWithFrame:frame];
    [createButton setText:@"+"];
    [createButton setTextColor:[UIColor whiteColor]];
    [createButton setTextAlignment:NSTextAlignmentCenter];
    [createButton setFont:[UIFont fontWithName:@"Montreal-Xlight" size:40]];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(createTribe:)];
    [createButton addGestureRecognizer:tap];
    [createButton setUserInteractionEnabled:YES];
    [topBar addSubview:createButton];
    
    // Adding a dark SIDEBAR
    frame = CGRectMake(self.view.bounds.size.height - 50, 0, 50, self.view.bounds.size.width);
    sideBar = [[UIView alloc] initWithFrame:frame];
    [sideBar setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [self.view addSubview:sideBar];
    
    frame = CGRectMake(0, 0, 50, 50);
    menuButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *menuImg = [UIImage imageNamed:@"button_menu.png"];
    [menuButton setImage:menuImg forState:UIControlStateNormal];
    //[menuButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [menuButton addTarget:self action:@selector(goToMenu:) forControlEvents:UIControlEventTouchUpInside];
    [sideBar addSubview:menuButton];
    
    frame = CGRectMake(0, 50, 50, (self.view.bounds.size.width - 100)/3);
    followingButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *followingImg = [UIImage imageNamed:@"button_following.png"];
    [followingButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [followingButton setImage:followingImg forState:UIControlStateNormal];
    //[sideBar addSubview:followingButton];
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(10, (self.view.bounds.size.width - 100)/3, 30, 1.0f);
    bottomBorder.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.5f].CGColor;
    [followingButton.layer addSublayer:bottomBorder];
    
    frame = CGRectMake(0, 50 + (self.view.bounds.size.width - 100)/3, 50, (self.view.bounds.size.width - 100)/3);
    contributingButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *contributingImg = [UIImage imageNamed:@"button_contributing.png"];
    [contributingButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [contributingButton setImage:contributingImg forState:UIControlStateNormal];
    //[sideBar addSubview:contributingButton];
    CALayer *bottomBorder2 = [CALayer layer];
    bottomBorder2.frame = CGRectMake(10, (self.view.bounds.size.width - 100)/3, 30, 1.0f);
    bottomBorder2.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.5f].CGColor;
    [contributingButton.layer addSublayer:bottomBorder2];
    
    frame = CGRectMake(0, 50 + (self.view.bounds.size.width - 100)*2/3, 50, (self.view.bounds.size.width - 100)/3);
    myTribesButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *myTribesImg = [UIImage imageNamed:@"button_mytribes.png"];
    [myTribesButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [myTribesButton setImage:myTribesImg forState:UIControlStateNormal];
    //[sideBar addSubview:myTribesButton];
    
    frame = CGRectMake(0, self.view.bounds.size.width - 50, 50, 50);
    captureButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *captureImg = [UIImage imageNamed:@"button_vybe.png"];
    [captureButton setImage:captureImg forState:UIControlStateNormal];
    //[captureButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [captureButton addTarget:self action:@selector(captureVybe:) forControlEvents:UIControlEventTouchUpInside];
    [sideBar addSubview:captureButton];
    
    flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.sectionInset = UIEdgeInsetsMake(50.0f, 10.0f, 20.0f, 10.0f);
    flowLayout.minimumLineSpacing = 50.0f;
    flowLayout.minimumInteritemSpacing = 20.0f;
    if (IS_IPHONE_5)
        flowLayout.itemSize = CGSizeMake(150.0f, 80.0f);
    else
        flowLayout.itemSize = CGSizeMake(120.0f, 80.0f);

    
    CGRect collectionFrame = CGRectMake(0, 50, self.view.bounds.size.height - 50, self.view.bounds.size.width - 50);
    collection = [[UICollectionView alloc] initWithFrame:collectionFrame collectionViewLayout:flowLayout];
    [collection registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    [collection registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
    [collection registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"footer"];
    collection.backgroundColor = [UIColor clearColor];
    collection.dataSource = self;
    collection.delegate = self;
    [self.view addSubview:collection];

    // Retries tribes for the user
    PFQuery *tribesQuery = [PFQuery queryWithClassName:kVYBTribeClassKey];
    [tribesQuery whereKey:kVYBTribeMembersKey equalTo:[PFUser currentUser]];
    [tribesQuery includeKey:kVYBTribeCreatorKey];
    //[tribesQuery includeKey:kVYBTribeMembersKey];
    
    [tribesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Network Temporarily Unavailable" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [av show];
            NSLog(@"Error: [SyncTribeViewController] tribe query failed.");
        } else {
            if ([objects count] > 0) {
                [[VYBMyTribeStore sharedStore] setMyTribes:objects];
                [collection reloadData];
            }
        }
    }];
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

- (void)captureVybe:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:NO];
}


// TODO: THIS IS DUMMY
- (void)createTribe:(id)sender {
    VYBCreateTribeViewController *createTribeVC = [[VYBCreateTribeViewController alloc] init];
    [self.navigationController presentViewController:createTribeVC animated:NO completion:nil];
}

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

    /*
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
    */
}



@end
