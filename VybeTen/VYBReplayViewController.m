//
//  VYBReplayViewController.m
//  VybeTen
//
//  Created by jinsuk on 3/9/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBReplayViewController.h"
#import "VYBPlayerView.h"
#import "VYBMyVybeStore.h"
#import "VYBCaptureViewController.h"
#import "VYBConstants.h"
#import "VYBSyncTribeViewController.h"
#import "UINavigationController+Fade.h"
#import "VYBLabel.h"
#import "VYBCache.h"

@implementation VYBReplayViewController {
    UILabel *selectYourTribeLabel;
}

@synthesize player = _player;
@synthesize playerItem = _playerItem;
@synthesize playerView = _playerView;
@synthesize currVybe;
@synthesize buttonDiscard, buttonSave, instruction, buttonCancel;
@synthesize syncLabel, syncButton;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBSyncViewControllerDidChangeSyncTribe object:nil];
}

- (void)loadView {
    NSLog(@"replay loadView");
    VYBPlayerView *playerView = [[VYBPlayerView alloc] init];
    self.view = playerView;
    [self.view setFrame:[[UIScreen mainScreen] bounds]];
    self.playerView = playerView;
}

- (void)viewDidLoad {
    NSLog(@"replay view loaded");
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeSyncTribeLabel:) name:VYBSyncViewControllerDidChangeSyncTribe object:nil];
    
    // Adding swipe gestures
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(saveVybe)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    [self.view addGestureRecognizer:swipeUp];
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(discardVybe)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeDown];
    
    /* First vybe instruction view */
    // Adjust brightness of a background video
    UIView *blackScreen = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.height, self.view.bounds.size.width)];
    [blackScreen setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.5]];
    [self.view addSubview:blackScreen];
    // REPLAY label
    UILabel *replay = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 200, 60)];
    [replay setText:@"REPLAYING"];
    [replay setTextColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
    [replay setFont:[UIFont fontWithName:@"Montreal-Light" size:26]];
    [self.view addSubview:replay];
    // Adding SAVE button
    UIButton *saveButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.height - 50, 0, 50, 50)];
    UIImage *buttonImg = [UIImage imageNamed:@"button_check.png"];
    [saveButton setContentMode:UIViewContentModeCenter];
    [saveButton addTarget:self action:@selector(saveVybe) forControlEvents:UIControlEventTouchUpInside];
    [saveButton setImage:buttonImg forState:UIControlStateNormal];
    [self.view addSubview:saveButton];
    // Adding CANCEL
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.height - 50, self.view.bounds.size.width - 50, 50, 50)];
    buttonImg = [UIImage imageNamed:@"button_cancel.png"];
    [cancelButton setContentMode:UIViewContentModeCenter];
    [cancelButton addTarget:self action:@selector(discardVybe) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setImage:buttonImg forState:UIControlStateNormal];
    [self.view addSubview:cancelButton];

    // Adding SYNC button
    CGRect frame = CGRectMake(0, self.view.bounds.size.width - 50, 50, 50);
    syncButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *syncNoneImg = [UIImage imageNamed:@"button_sync_none.png"];
    UIImage *syncImg = [UIImage imageNamed:@"button_sync.png"];
    [syncButton setImage:syncNoneImg forState:UIControlStateNormal];
    [syncButton setImage:syncImg forState:UIControlStateSelected];
    [syncButton setContentMode:UIViewContentModeLeft];
    [syncButton addTarget:self action:@selector(changeSync:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:syncButton];
    // Adding SYNC label
    frame = CGRectMake(50, self.view.bounds.size.width - 50, 150, 50);
    syncLabel = [[VYBLabel alloc] initWithFrame:frame];
    [syncLabel setTextColor:[UIColor whiteColor]];
    [syncLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20]];
    [self.view addSubview:syncLabel];
    PFObject *tribe = [[VYBCache sharedCache] syncTribeForUser:[PFUser currentUser]];
    if (tribe) {
        [syncLabel setText:tribe[kVYBTribeNameKey]];
        [syncButton setSelected:YES];
    } else {
        [syncLabel setText:@"(select)"];
        [syncButton setSelected:NO];
    }
    
    // Adding SELECT label
    frame = CGRectMake((self.view.bounds.size.height - 200) / 2, (self.view.bounds.size.width - 40) / 2, 200, 40);
    selectYourTribeLabel = [[UILabel alloc] initWithFrame:frame];
    [selectYourTribeLabel setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.5]];
    [selectYourTribeLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:28]];
    [selectYourTribeLabel setTextColor:[UIColor whiteColor]];
    [selectYourTribeLabel setTextAlignment:NSTextAlignmentCenter];
    [selectYourTribeLabel setText:@"Select your tribe"];
    [self.view addSubview:selectYourTribeLabel];
    selectYourTribeLabel.hidden = YES;
    
    [self playVideo];
}


- (void)changeSync:(id)sender {
    VYBSyncTribeViewController *syncVC = [[VYBSyncTribeViewController alloc] init];
    [self.navigationController presentViewController:syncVC animated:NO completion:nil];
}

- (void)changeSyncTribeLabel:(NSNotification *)note {
    PFObject *tribe = [[VYBCache sharedCache] syncTribeForUser:[PFUser currentUser]];
    [syncLabel setText:tribe[kVYBTribeNameKey]];
    [syncButton setSelected:YES];
}

- (void)saveVybe {
    // Promt a message to choose a vybe to sync
    if (![[VYBCache sharedCache] syncTribeForUser:[PFUser currentUser]]) {
        selectYourTribeLabel.hidden = NO;
    }
    else {
        //[[VYBMyVybeStore sharedStore] vybeForKey:self.vybeKey] setObject:[ forKey:(NSString *)
        PFObject *tribe = [[VYBCache sharedCache] syncTribeForUser:[PFUser currentUser]];
        [currVybe setTribeObjectID:tribe.objectId];
        [[VYBMyVybeStore sharedStore] addVybe:currVybe];
        [[VYBMyVybeStore sharedStore] uploadVybe:currVybe];
        [self.navigationController popViewControllerAnimated:NO];

    }
}

- (void)discardVybe {
    NSURL *videoURL = [[NSURL alloc] initFileURLWithPath:[currVybe videoFilePath]];
    NSURL *thumbURL = [[NSURL alloc] initFileURLWithPath:[currVybe thumbnailFilePath]];
    
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtURL:videoURL error:&error];
    [[NSFileManager defaultManager] removeItemAtURL:thumbURL error:&error];
    
    [self.navigationController popViewControllerAnimated:NO];
}


- (void)playVideo {
    NSURL *videoURL = [[NSURL alloc] initFileURLWithPath:[currVybe videoFilePath]];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    // For play loop
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    [self setPlayer:[AVPlayer playerWithPlayerItem:self.playerItem]];
    [self.playerView setPlayer:self.player];
    [self.playerView setVideoFillMode];
    [self.player play];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    NSLog(@"playerItemDidReachEnd");
    [self.playerItem seekToTime:kCMTimeZero];
    [self.player play];
}


/**
 * Functions to act as a delegate for UITableView
 **/
/*
 
- (void)saveVybe {
    
     UITableViewController *tableVC = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
     [tableVC.tableView setDelegate:self];
     [tableVC.tableView setDataSource:self];
     [tableVC.tableView setBackgroundColor:[UIColor clearColor]];
     [tableVC.tableView setRowHeight:60.0f];
     [tableVC.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
     [tableVC.tableView setShowsVerticalScrollIndicator:NO];
     UIToolbar* blurredView = [[UIToolbar alloc] initWithFrame:tableVC.tableView.bounds];
     [blurredView setBarStyle:UIBarStyleBlack];
     [tableVC.tableView setBackgroundView:blurredView];
     // Brighten the background when blurred view lies upon
     [self.view setBackgroundColor:[UIColor clearColor]];
     
     // Adding CANCEL button
     CGRect buttonCancelFrame = CGRectMake(tableVC.tableView.bounds.size.height - 50, tableVC.tableView.bounds.size.width - 50, 50, 50);
     buttonCancel = [[UIButton alloc] initWithFrame:buttonCancelFrame];
     UIImage *cancelImage = [UIImage imageNamed:@"button_cancel.png"];
     [buttonCancel setImage:cancelImage forState:UIControlStateNormal];
     [buttonCancel addTarget:self action:@selector(goBack:) forControlEvents:UIControlEventTouchUpInside];
     // Dealing with the buttons position when table is scrolled will be done here
     [tableVC.tableView addSubview:buttonCancel];
     
     [self.navigationController pushViewController:tableVC animated:NO];
     //if ([[[VYBMyTribeStore sharedStore] myTribes] count] < 1)
     //[[VYBMyTribeStore sharedStore] refreshTribes];
}
 
- (void)goBack:(id)sender {
 [self.navigationController popViewControllerAnimated:NO];
}
 
 
 
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //NSLog(@"[ReplayViewController]There are %d tribes", [[[[VYBMyTribeStore sharedStore] myTribesVybes] allKeys] count]);
    return [[[VYBMyTribeStore sharedStore] myTribes] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableCell"];
    }
    NSString *tribeName = [[[[VYBMyTribeStore sharedStore] myTribes] objectAtIndex:[indexPath row]] tribeName];
    // Save the captured vybe in MyVybeStore
    [cell.textLabel setText:tribeName];
    [cell.textLabel setFont:[UIFont fontWithName:@"Montreal-Light" size:20]];

    //[cell.textLabel setFont:[UIFont fontWithName:@"" size:20]];
    [cell.textLabel setTextColor:[UIColor colorWithWhite:1.0 alpha:0.6]];
    
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSLog(@"Cell %@ selected, let's make the text big", [cell.textLabel text]);
    [cell.textLabel setFont:[UIFont systemFontOfSize:24]];
    [cell.textLabel setTextColor:[UIColor whiteColor]];
 
}

*/


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
