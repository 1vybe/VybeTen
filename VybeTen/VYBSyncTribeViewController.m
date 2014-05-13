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

@implementation VYBSyncTribeViewController {
    UITableView *tribeTable;
    
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    
    if ([[[VYBMyTribeStore sharedStore] myTribes] count] == 0) {
        [[VYBMyTribeStore sharedStore] refreshTribesWithCompletion:^(NSError *err) {
            if (!err) {
                [tribeTable reloadData];
            }
            else {
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Network Temporarily Unavailable" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [av show];
            }
        }];
    }
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
    VYBTribe *tribe = [[[VYBMyTribeStore sharedStore] myTribes] objectAtIndex:[indexPath row]];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    //[cell setExclusiveTouch:NO];
    [[cell textLabel] setTextColor:[UIColor whiteColor]];
    [[cell textLabel] setText:[tribe tribeName]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    VYBTribe *tribe = [[[VYBMyTribeStore sharedStore] myTribes] objectAtIndex:[indexPath row]];
    
    if (self.completionBlock)
        [self completionBlock](tribe);
    
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

@end
