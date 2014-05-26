//
//  VYBFriendsViewController.m
//  VybeTen
//
//  Created by jinsuk on 4/25/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBAddMemberViewController.h"
#import "VYBInviteViewController.h"
#import "VYBCache.h"
#import "MBProgressHUD.h"
#import "VYBImageStore.h"
#import "VYBFriendCollectionCell.h"

@implementation VYBAddMemberViewController {
    UIView *topBar;
    UILabel *screenTitleLabel;
    UIButton *backButton;
    UIButton *searchButton;
    UILabel *inviteButton;
    
    UIView *sideBar;
    UIButton *confirmButton;
    UIButton *cancelButton;
    UIButton *alreadyMembersTabButton;
    UIButton *nonMembersTabButton;
    
    UICollectionView *collectionView;
    UICollectionViewFlowLayout *flowLayout;
    
    PFQuery *friendsQuery;
    
    NSMutableArray *selectedIndexes;
    NSMutableArray *alreadyMembers;
    NSMutableArray *nonMembers;
}

@synthesize objects = _objects;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        selectedIndexes = [[NSMutableArray alloc] init];
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
    // Adding BACK button
    frame = CGRectMake(0, 0, 50, 50);
    backButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *backImage = [UIImage imageNamed:@"button_back.png"];
    [backButton setContentMode:UIViewContentModeCenter];
    [backButton setImage:backImage forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(didTapBackButton:) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:backButton];
    // Adding Label
    frame = CGRectMake(60, 0, 180, 50);
    screenTitleLabel = [[UILabel alloc] initWithFrame:frame];
    [screenTitleLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20.0]];
    [screenTitleLabel setTextColor:[UIColor whiteColor]];
    [screenTitleLabel setText:@"M E M B E R S"];
    [topBar addSubview:screenTitleLabel];
    // Adding SEARCH button
    frame = CGRectMake(self.view.bounds.size.height - 100, 0, 50, 50);
    searchButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *searchImg = [UIImage imageNamed:@"button_search.png"];
    [searchButton setImage:searchImg forState:UIControlStateNormal];
    [topBar addSubview:searchButton];

    // Adding Invite friends button
    frame = CGRectMake(self.view.bounds.size.height - 150, 0, 50, 50);
    inviteButton = [[UILabel alloc] initWithFrame:frame];
    [inviteButton setText:@"+"];
    [inviteButton setTextColor:[UIColor whiteColor]];
    [inviteButton setTextAlignment:NSTextAlignmentCenter];
    [inviteButton setFont:[UIFont fontWithName:@"Montreal-Xlight" size:40]];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addFriend:)];
    [inviteButton addGestureRecognizer:tap];
    [inviteButton setUserInteractionEnabled:YES];
    [topBar addSubview:inviteButton];
    
    // Adding a dark SIDEBAR
    frame = CGRectMake(self.view.bounds.size.height - 50, 0, 50, self.view.bounds.size.width);
    sideBar = [[UIView alloc] initWithFrame:frame];
    [sideBar setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [self.view addSubview:sideBar];
    // Adding CONFIRM button
    frame = CGRectMake(0, 0, 50, 50);
    confirmButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *confimImg = [UIImage imageNamed:@"button_check.png"];
    [confirmButton setImage:confimImg forState:UIControlStateNormal];
    [confirmButton addTarget:self action:@selector(didTapConfirmButton:) forControlEvents:UIControlEventTouchUpInside];
    [sideBar addSubview:confirmButton];
    // Adding a tab button
    frame = CGRectMake(0, 50, 50, (self.view.bounds.size.width - 100)/2);
    alreadyMembersTabButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *alreadyMembersImg = [UIImage imageNamed:@"button_friends.png"];
    [alreadyMembersTabButton setImage:alreadyMembersImg forState:UIControlStateNormal];
    [alreadyMembersTabButton addTarget:self action:@selector(alreadyMembersTabSelected:) forControlEvents:UIControlEventTouchUpInside];
    [sideBar addSubview:alreadyMembersTabButton];
    // Adding another tab button
    frame = CGRectMake(0, self.view.bounds.size.width/2, 50, (self.view.bounds.size.width - 100)/2);
    nonMembersTabButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *nonMembersImg = [UIImage imageNamed:@"button_featured.png"];
    [nonMembersTabButton setImage:nonMembersImg forState:UIControlStateNormal];
    [nonMembersTabButton addTarget:self action:@selector(nonMembersTabSelected:) forControlEvents:UIControlEventTouchUpInside];
    [sideBar addSubview:nonMembersTabButton];
    // Adding CANCEL button
    frame = CGRectMake(0, self.view.bounds.size.width - 50, 50, 50);
    cancelButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *cancelImg = [UIImage imageNamed:@"button_cancel.png"];
    [cancelButton setImage:cancelImg forState:UIControlStateNormal];
    //[captureButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [cancelButton addTarget:self action:@selector(didTapCancelButton:) forControlEvents:UIControlEventTouchUpInside];
    [sideBar addSubview:cancelButton];
    
    
    flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.sectionInset = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
    //flowLayout.minimumLineSpacing = 50.0f;
    flowLayout.minimumInteritemSpacing = 10.0f;
    /*
     if (IS_IPHONE_5)
     flowLayout.itemSize = CGSizeMake(150.0f, 80.0f);
     else
     flowLayout.itemSize = CGSizeMake(120.0f, 80.0f);
     */
    
    CGRect collectionFrame = CGRectMake(0, 50, self.view.bounds.size.height - 50, self.view.bounds.size.width - 50);
    collectionView = [[UICollectionView alloc] initWithFrame:collectionFrame collectionViewLayout:flowLayout];
    [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    [collectionView registerClass:[VYBFriendCollectionCell class] forCellWithReuseIdentifier:@"FriendCell"];
    [collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
    [collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"footer"];
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    [self.view addSubview:collectionView];
   
    
    //[self alreadyMembersTabSelected:nil];
    [alreadyMembersTabButton setSelected:YES];
    [self alreadyMembersTabSelected:nil];
}

- (void)alreadyMembersTabSelected:(id)sender {
    if (alreadyMembers) {
        _objects = alreadyMembers;
        [collectionView reloadData];
    } else {
        alreadyMembers = [[NSMutableArray alloc] init];
        // PFQuery for members for this tribe
        PFRelation *relation = [self.currTribe relationForKey:kVYBTribeMembersKey];
        PFQuery *members = [relation query];
        [MBProgressHUD showHUDAddedTo:collectionView animated:YES];
        [members findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                for (PFUser *member in objects) {
                    if (![member.objectId isEqual:[[PFUser currentUser] objectId]]) {
                        [alreadyMembers addObject:member];
                    }
                }
                _objects = alreadyMembers;
                [collectionView reloadData];
            }
            [MBProgressHUD hideAllHUDsForView:collectionView animated:YES];
        }];
    }
    
    [nonMembersTabButton setSelected:NO];
    collectionView.allowsMultipleSelection = NO;
    
    confirmButton.hidden = YES;
    cancelButton.hidden = YES;
}

- (void)nonMembersTabSelected:(id)sender {
    if (nonMembers) {
        _objects = nonMembers;
        [collectionView reloadData];
    } else {
        nonMembers = [[NSMutableArray alloc] init];
        // PFQuery for retrieving a list of friends on Vybe
        NSArray *facebookFriends = [[VYBCache sharedCache] facebookFriends];
        friendsQuery = [PFUser query];
        if (facebookFriends) {
            [friendsQuery whereKey:kVYBUserFacebookIDKey containedIn:facebookFriends];
            [MBProgressHUD showHUDAddedTo:collectionView animated:YES];
            [friendsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (error) {
                } else {
                    for (PFUser *friend in objects) {
                        if (![self isAlreadyMember:friend]) {
                            [nonMembers addObject:friend];
                        }
                    }
                    _objects = nonMembers;
                    [collectionView reloadData];
                }
                [MBProgressHUD hideAllHUDsForView:collectionView animated:YES];
            }];
        }
    }
    [alreadyMembersTabButton setSelected:NO];
    collectionView.allowsMultipleSelection = YES;
    [selectedIndexes removeAllObjects];
    
    confirmButton.hidden = NO;
    cancelButton.hidden = NO;
}

- (BOOL)isAlreadyMember:(PFUser *)aUser {
    for (PFUser *member in alreadyMembers) {
        if ([member.objectId isEqual:aUser.objectId]) {
            return YES;
        }
    }
    return NO;
}

- (void)didTapBackButton:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)didTapConfirmButton:(id)sender {
    if (selectedIndexes.count < 1) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Choose a friend" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [av show];
    } else {
        PFObject *currTribe = self.currTribe;
        PFACL *tribeACL = currTribe.ACL;
        
        PFRelation *members = [currTribe relationForKey:kVYBTribeMembersKey];
        for (PFUser *newMember in selectedIndexes) {
            [members addObject:newMember];
            [tribeACL setReadAccess:YES forUser:newMember];
            [tribeACL setWriteAccess:YES forUser:newMember];
        }
        currTribe.ACL = tribeACL;
        [currTribe saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                NSLog(@"Members added");
            } else {
                
            }
        }];
        [self.navigationController popViewControllerAnimated:NO];
    }
}

- (void)didTapCancelButton:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)inviteFriend:(id)sender {
    VYBInviteViewController *inviteVC = [[VYBInviteViewController alloc] init];
    [self.navigationController pushViewController:inviteVC animated:NO];
}


#pragma mark - UICollectionViewDelegateFlowLayout

/*
 - (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
 return CGSizeMake(0.0f, 30.0f);
 }
 */

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)aCollectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)aCollectionView numberOfItemsInSection:(NSInteger)section {
    return [_objects count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)aCollectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *FriendCellIdentifier = @"FriendCell";
    
    PFUser *usr = [_objects objectAtIndex:[indexPath row]];
    VYBFriendCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:FriendCellIdentifier forIndexPath:indexPath];
    [cell setUser:usr];
    if ([selectedIndexes containsObject:usr]) {
        [cell setSelected:YES];
    } else {
        [cell setSelected:NO];
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    int height = 80;
    int width;
    if (IS_IPHONE_5) { width = 230; } else { width = 210; }
    
    
    return CGSizeMake(width, height);
}

- (void)collectionView:(UICollectionView *)aCollectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PFUser *usr = [_objects objectAtIndex:[indexPath row]];
    if (usr) {
        [selectedIndexes addObject:usr];
    }
}

- (void)collectionView:(UICollectionView *)aCollectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    PFUser *usr = [_objects objectAtIndex:[indexPath row]];
    if (usr) {
        [selectedIndexes removeObject:usr];
    }
}

- (void)followToggled:(id)sender {
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}



@end
