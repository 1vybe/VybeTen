//
//  VYBSyncTribeTableViewController.m
//  VybeTen
//
//  Created by jinsuk on 4/13/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBSyncTribeViewController.h"
#import "VYBMyTribeStore.h"
#import "UINavigationController+Fade.h"
#import "VYBCreateTribeViewController.h"
#import "VYBCache.h"

@implementation VYBSyncTribeViewController {
    UITableView *tribeTable;
}

- (void)dealloc {
    
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
    
    frame = CGRectMake(0, 0, 150, self.view.bounds.size.width);
    UIToolbar *menuBackground = [[UIToolbar alloc] initWithFrame:frame];
    [menuBackground setBarStyle:UIBarStyleBlack];
    [self.view addSubview:menuBackground];

    frame = CGRectMake(0, 0, 150, 50);
    UIButton *createTribe = [[UIButton alloc] initWithFrame:frame];
    [createTribe.titleLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20]];
    [createTribe setTitle:@"Create +" forState:UIControlStateNormal];
    [createTribe setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.5]];
    [createTribe addTarget:self action:@selector(createTribePressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:createTribe];
    
    frame = CGRectMake(0, 50, 150, self.view.bounds.size.width - 100);
    tribeTable = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    [tribeTable setDelegate:self];
    [tribeTable setDataSource:self];
    [tribeTable setUserInteractionEnabled:YES];
    //[tribeTable setExclusiveTouch:NO];
    //[tribeTable setAllowsSelection:YES];
    [tribeTable setBackgroundColor:[UIColor clearColor]];
    [tribeTable setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.view addSubview:tribeTable];
    
    
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
                [tribeTable reloadData];
            }
        }
    }];
}


- (void)createTribePressed:(id)sender {
    VYBCreateTribeViewController *createTribeVC = [[VYBCreateTribeViewController alloc] init];
    [self.navigationController presentViewController:createTribeVC animated:NO completion:nil];
}

- (void)dismissSyncTribeMenu {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[VYBMyTribeStore sharedStore] myTribes] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SyncTribeTableCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SyncTribeTableCell"];
        [cell setBackgroundColor:[UIColor clearColor]];
    }
    [[cell textLabel] setFont:[UIFont fontWithName:@"Montreal-Xlight" size:16]];
    PFObject *tribe = [[[VYBMyTribeStore sharedStore] myTribes] objectAtIndex:[indexPath row]];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    //[cell setExclusiveTouch:NO];
    [[cell textLabel] setTextColor:[UIColor whiteColor]];
    [[cell textLabel] setText:tribe[kVYBTribeNameKey]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PFObject *tribe = [[[VYBMyTribeStore sharedStore] myTribes] objectAtIndex:[indexPath row]];
    
    [[VYBCache sharedCache] setSyncTribe:tribe user:[PFUser currentUser]];
    [[NSNotificationCenter defaultCenter] postNotificationName:VYBSyncViewControllerDidChangeSyncTribe object:nil];
    
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}


@end
