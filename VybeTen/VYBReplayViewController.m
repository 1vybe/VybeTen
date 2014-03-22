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
#import "VYBMyTribeStore.h"
#import "VYBCaptureViewController.h"
#import "VYBConstants.h"

@implementation VYBReplayViewController

@synthesize player = _player;
@synthesize playerItem = _playerItem;
@synthesize playerView = _playerView;
@synthesize vybe = _vybe;
@synthesize replayURL = _replayURL;
@synthesize buttonDiscard, buttonSave, instruction;

- (void)loadView {
    NSLog(@"replay loadView");
    VYBPlayerView *playerView = [[VYBPlayerView alloc] init];
    self.view = playerView;
    [self.view setFrame:[[UIScreen mainScreen] bounds]];
    self.playerView = playerView;
}
- (void)viewDidLoad
{
    NSLog(@"replay view loaded");
    [super viewDidLoad];

    // Adding swipe gestures
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(saveVybe)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    [self.view addGestureRecognizer:swipeUp];
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(discardVybe)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeDown];
    
    /* First vybe instruction view */
    // Adjust brightness of a background video
    [self.view setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
    UIImageView *instructionImg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.height, self.view.bounds.size.width)];
    [instructionImg setContentMode:UIViewContentModeScaleToFill];
    [instructionImg setImage:[UIImage imageNamed:@"firstvid.png"]];
    [self.view addSubview:instructionImg];
    
    [self playVideo];
}

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
    CGRect buttonCancelFrame = CGRectMake(tableVC.tableView.bounds.size.height - 40, tableVC.tableView.bounds.size.width -40, 34, 34);
    UIButton *buttonCancel = [[UIButton alloc] initWithFrame:buttonCancelFrame];
    UIImage *cancelImage = [UIImage imageNamed:@"button_cancel.png"];
    [buttonCancel setImage:cancelImage forState:UIControlStateNormal];
    [buttonCancel addTarget:self action:@selector(discardVybe) forControlEvents:UIControlEventTouchUpInside];
    [tableVC.tableView addSubview:buttonCancel];
    
    [self.navigationController pushViewController:tableVC animated:NO];
    [[VYBMyTribeStore sharedStore] refreshTribes];
}

- (void)discardVybe {
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtURL:self.replayURL error:&error];
    if (error)
        NSLog(@"Removing a file failed: %@", error);
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)playVideo {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:self.replayURL options:nil];
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    // For play loop
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    [self setPlayer:[AVPlayer playerWithPlayerItem:self.playerItem]];
    [self.playerView setPlayer:self.player];
    [self.playerView setVideoFillMode];
    [self.player play];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self.playerItem seekToTime:kCMTimeZero];
    [self.player play];
}

/**
 * Functions to act as a delegate for UITableView 
 **/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"[ReplayViewController]There are %d tribes", [[[[VYBMyTribeStore sharedStore] myTribesVybes] allKeys] count]);
    return [[[[VYBMyTribeStore sharedStore] myTribesVybes] allKeys] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableCell"];
    }
    NSString *tribeName = [[[[VYBMyTribeStore sharedStore] myTribesVybes] allKeys] objectAtIndex:[indexPath row]];
    // Save the captured vybe in MyVybeStore
    [cell.textLabel setText:tribeName];
    [cell.textLabel setFont:[UIFont systemFontOfSize:20]];
    //[cell.textLabel setFont:[UIFont fontWithName:@"" size:20]];
    [cell.textLabel setTextColor:[UIColor colorWithWhite:1.0 alpha:0.6]];
    
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
    
    return cell;
}

/* Actual saving of a vybe and uploading are started when a user chooses which Tribe to upload to */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSLog(@"Cell %@ selected, let's make the text big", [cell.textLabel text]);
    [cell.textLabel setFont:[UIFont systemFontOfSize:24]];
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    NSString *tribeName = [[[[VYBMyTribeStore sharedStore] myTribesVybes] allKeys] objectAtIndex:[indexPath row]];

    [self performSelector:@selector(uploadForTribe:) withObject:tribeName afterDelay:0.3];
}

- (void)uploadForTribe:(NSString *)tribeName {
    // Save the captured vybe in MyVybeStore
    if (tribeName) {
        [self.vybe setTribeName: tribeName];
        [[VYBMyVybeStore sharedStore] addVybe:self.vybe];
    }
    [self.navigationController popToRootViewControllerAnimated:NO];
}

/**
 * Repositioning floating views during/after scroll
 **/
/*
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect frame = self.buttonMenu.frame;
    frame.origin.y = scrollView.contentOffset.y;
    self.buttonMenu.frame = frame;
    
    CGRect frameTwo = self.buttonCapture.frame;
    frameTwo.origin.y =scrollView.contentOffset.y + self.view.bounds.size.height - 48;
    self.buttonCapture.frame = frameTwo;
    
    [[self view] bringSubviewToFront:self.buttonMenu];
    [[self view] bringSubviewToFront:self.buttonCapture];
}
*/
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
