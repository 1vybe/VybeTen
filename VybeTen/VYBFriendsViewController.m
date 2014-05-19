//
//  VYBFriendsViewController.m
//  VybeTen
//
//  Created by jinsuk on 4/25/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Parse/Parse.h>
#import "VYBFriendsViewController.h"
#import "VYBMenuViewController.h"
#import "VYBInviteViewController.h"
#import "VYBConstants.h"
#import "VYBCache.h"
#import "MBProgressHUD.h"
#import "VYBImageStore.h"

@implementation VYBFriendsViewController {
    UIView *topBar;
    UILabel *currentTabLabel;
    UILabel *createButton;
    
    UIView *sideBar;
    UIButton *searchButton;
    UIButton *captureButton;
    UIButton *menuButton;
    
    UICollectionView *collectionView;
    UICollectionViewFlowLayout *flowLayout;
    
    PFQuery *friendsQuery;
}

@synthesize objects = _objects;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    [topBar addSubview:searchButton];
    // Adding Label
    frame = CGRectMake(10, 0, 150, 50);
    currentTabLabel = [[UILabel alloc] initWithFrame:frame];
    [currentTabLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20.0]];
    [currentTabLabel setTextColor:[UIColor whiteColor]];
    [currentTabLabel setText:@"F R I E N D S"];
    [topBar addSubview:currentTabLabel];
    // Adding CREATE(Tribe) button
    frame = CGRectMake(self.view.bounds.size.height - 150, 0, 50, 50);
    createButton = [[UILabel alloc] initWithFrame:frame];
    [createButton setText:@"+"];
    [createButton setTextColor:[UIColor whiteColor]];
    [createButton setTextAlignment:NSTextAlignmentCenter];
    [createButton setFont:[UIFont fontWithName:@"Montreal-Xlight" size:40]];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addFriend:)];
    [createButton addGestureRecognizer:tap];
    [createButton setUserInteractionEnabled:YES];
    [topBar addSubview:createButton];
    
    // Adding a dark SIDEBAR
    frame = CGRectMake(self.view.bounds.size.height - 50, 0, 50, self.view.bounds.size.width);
    sideBar = [[UIView alloc] initWithFrame:frame];
    [sideBar setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [self.view addSubview:sideBar];
    // Adding MENU button
    frame = CGRectMake(0, 0, 50, 50);
    menuButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *menuImg = [UIImage imageNamed:@"button_menu.png"];
    [menuButton setImage:menuImg forState:UIControlStateNormal];
    //[menuButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [menuButton addTarget:self action:@selector(goToMenu:) forControlEvents:UIControlEventTouchUpInside];
    [sideBar addSubview:menuButton];
    
    // Adding CAPTURE button
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
    collectionView = [[UICollectionView alloc] initWithFrame:collectionFrame collectionViewLayout:flowLayout];
    [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    [collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
    [collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"footer"];
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    [self.view addSubview:collectionView];
    
    // PFQuery for retrieving a list of friends on Vybe
    NSArray *facebookFriends = [[VYBCache sharedCache] facebookFriends];
    friendsQuery = [PFUser query];
    if (facebookFriends) {
        [friendsQuery whereKey:kVYBUserFacebookIDKey containedIn:facebookFriends];
        [MBProgressHUD showHUDAddedTo:collectionView animated:YES];
        NSMutableArray *newObjects = [NSMutableArray array];
        [friendsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (error) {
                
            } else {
                for (PFUser *user in objects) {
                    [newObjects addObject:user];
                }
                // PFQuery for follow status
                PFQuery *isFollowedByCurrentUser = [PFQuery queryWithClassName:kVYBActivityClassKey];
                [isFollowedByCurrentUser whereKey:kVYBActivityFromUserKey equalTo:[PFUser currentUser]];
                [isFollowedByCurrentUser whereKey:kVYBActivityToUserKey containedIn:self.objects];
                [isFollowedByCurrentUser whereKey:kVYBActivityTypeKey equalTo:kVYBActivityTypeFollow];
                [isFollowedByCurrentUser setCachePolicy:kPFCachePolicyNetworkOnly];
                
                // Already running in background so call blocking method
                NSError *err;
                NSArray *followings = [isFollowedByCurrentUser findObjects:&err];
                if (followings && [followings count] > 0) {
                    for (PFObject *following in followings) {
                        [[VYBCache sharedCache] setFollowStatus:YES user:following[kVYBActivityToUserKey]];
                    }
                }
                _objects = newObjects;
                [collectionView reloadData];
            }
            [MBProgressHUD hideAllHUDsForView:collectionView animated:YES];
        }];
    }
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

- (void)addFriend:(id)sender {
    VYBInviteViewController *inviteVC = [[VYBInviteViewController alloc] init];
    [self.navigationController pushViewController:inviteVC animated:NO];
}


#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(0.0f, 30.0f);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_objects count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];

    cell.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];

    PFUser *usr = [_objects objectAtIndex:[indexPath row]];
    
    [self cell:cell setDisplayName:usr[kVYBUserDisplayNameKey] profilePictureForUser:usr indexPath:indexPath];
    return cell;
}

- (void)cell:(UICollectionViewCell *)cell setDisplayName:(NSString *)name profilePictureForUser:(PFUser *)user indexPath:(NSIndexPath *)indexPath {
    // Get current cell size
    //CGSize itemSize = [self collectionView:collection layout:flowLayout sizeForItemAtIndexPath:indexPath];
    int top = -30;
    int height = 80;
    int width;
    if (IS_IPHONE_5)
        width = 150;
    else
        width = 120;
    
    
    PFFile *profileFile = user[kVYBUserProfilePicSmallKey];
    PFImageView *profileImageView = [[PFImageView alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
    [profileImageView setImage:[UIImage imageNamed:@"user_no_thumbnail.png"]];
    if (profileFile) {
        [profileImageView setFile:profileFile];
        [profileImageView loadInBackground];
    }
    profileImageView.tag = 77;
    [self removeReusedLabel:cell tag:77];
    [cell addSubview:profileImageView];
    
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, 0, width - 70, 30)];
    [nameLabel setBackgroundColor:[UIColor clearColor]];
    nameLabel.tag = 33;
    [nameLabel setTextColor:[UIColor whiteColor]];
    [nameLabel setText:name];
    [nameLabel setTextAlignment:NSTextAlignmentLeft];
    [nameLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:18]];
    [self removeReusedLabel:cell tag:33];
    [cell addSubview:nameLabel];
    
    UIButton *followButton = [[UIButton alloc] initWithFrame:CGRectMake(70, 50, width - 70, 30)];
    [followButton setTitle:([[VYBCache sharedCache] followStatusForUser:user]) ? @"Following" : @"Follow" forState:UIControlStateNormal];
    followButton.tag = 37;
    [self removeReusedLabel:cell tag:37];
    [cell addSubview:followButton];
}

- (void)removeReusedLabel:(UICollectionViewCell *)cell tag:(int)tag {
    UILabel *foundLabelBackground = (UILabel *)[cell viewWithTag:tag];
    if (foundLabelBackground) [foundLabelBackground removeFromSuperview];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}



@end
