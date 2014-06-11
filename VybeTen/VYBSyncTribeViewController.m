//
//  VYBSyncTribeTableViewController.m
//  VybeTen
//
//  Created by jinsuk on 4/13/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBSyncTribeViewController.h"
#import "UINavigationController+Fade.h"
#import "VYBCache.h"

@implementation VYBSyncTribeViewController {
    VYBCreateTribeViewController *createTribeVC;
}

- (void)dealloc {
    
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.paginationEnabled = NO;
        
        self.pullToRefreshEnabled = NO;
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTribes:) name:VYBMyTribeStoreDidRefreshTribes object:nil];
    
    CGRect frame = CGRectMake(150, 0, self.view.bounds.size.height - 150, self.view.bounds.size.width);
    UIView *tapView = [[UIView alloc] initWithFrame:frame];
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissSyncTribeMenu)];
    [tapView addGestureRecognizer:tapRecognizer];
    [self.view addSubview:tapView];

    frame = CGRectMake(0, 0, 150, 50);
    UIButton *createTribe = [[UIButton alloc] initWithFrame:frame];
    [createTribe.titleLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20]];
    [createTribe setTitle:@"Create +" forState:UIControlStateNormal];
    [createTribe setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.5]];
    [createTribe addTarget:self action:@selector(createTribePressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:createTribe];
    
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView setSeparatorColor:[UIColor clearColor]];
}



#pragma mark - PFQueryTableViewController

- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:kVYBTribeClassKey];
    
    [query whereKey:kVYBTribeMembersKey equalTo:[PFUser currentUser]];
    
    if (self.objects.count == 0) {
        //query.cachePolicy = kPFCachePolicyCacheElseNetwork;
    }
    
    [query orderByAscending:kVYBTribeNameKey];
    
    return query;
}


#pragma mark - UITableViewController 

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *SyncTribeCellIdentifier = @"SyncTribeCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SyncTribeCellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SyncTribeCellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.contentView.backgroundColor = [UIColor clearColor];
    }
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.text = [object objectForKey:kVYBTribeNameKey];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject *aTribe = [self objectAtIndexPath:indexPath];
    [[VYBCache sharedCache] setSyncTribe:aTribe user:[PFUser currentUser]];
    [[NSNotificationCenter defaultCenter] postNotificationName:VYBSyncViewControllerDidChangeSyncTribe object:nil];
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50.0f;
}


- (void)createTribePressed:(id)sender {
    createTribeVC = [[VYBCreateTribeViewController alloc] init];
    createTribeVC.delegate = self;
    [self presentViewController:createTribeVC animated:NO completion:nil];
}

- (void)dismissSyncTribeMenu {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - VYBCreateTribeViewControllerDelegate

- (void)createdTribe:(PFObject *)aTribe {
    [[VYBCache sharedCache] setSyncTribe:aTribe user:[PFUser currentUser]];
    [[NSNotificationCenter defaultCenter] postNotificationName:VYBSyncViewControllerDidChangeSyncTribe object:nil];
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}


@end
