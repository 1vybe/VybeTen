//
//  VYBTribeVybesViewController.m
//  VybeTen
//
//  Created by jinsuk on 3/20/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBTribeVybesViewController.h"
#import "VYBPlayerViewController.h"
#import "VYBVybeCell.h"
#import "VYBImageStore.h"
#import "VYBMyTribeStore.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"
#import "VYBMenuViewController.h"

@implementation VYBTribeVybesViewController {
    UIView *topBar;
    UIButton *menuButton;    
    UIButton *friendsButton;
}
@synthesize buttonCapture = _buttonCapture;
@synthesize buttonBack = _buttonBack;
@synthesize currTribe = _currTribe;
@synthesize countLabel = _countLabel;

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    return [self init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.frame = CGRectMake(0, 0, self.tableView.frame.size.width, self.tableView.frame.size.height);
    // Rotate the tableView clockwise for horizontal scrolling
    CGAffineTransform rotateTable = CGAffineTransformMakeRotation(M_PI_2);
    self.tableView.transform = rotateTable;
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView setRowHeight:200.0f];
    self.tableView.showsVerticalScrollIndicator = NO;
    UIToolbar* blurredView = [[UIToolbar alloc] initWithFrame:self.tableView.bounds];
    [blurredView setBarStyle:UIBarStyleBlack];
    [self.tableView setBackgroundView:blurredView];
    
    
    // Adding a dark TOPBAR
    CGRect frame = CGRectMake(0, 0, 50, self.view.bounds.size.height);
    topBar = [[UIView alloc] initWithFrame:frame];
    [topBar setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.1]];
    [self.view addSubview:topBar];
    // Adding BACK button
    CGRect buttonBackFrame = CGRectMake(0, self.view.bounds.size.height - 50, 50, 50);
    self.buttonBack = [[UIButton alloc] initWithFrame:buttonBackFrame];
    UIImage *backImage = [UIImage imageNamed:@"button_back.png"];
    [self.buttonBack setContentMode:UIViewContentModeCenter];
    [self.buttonBack setImage:backImage forState:UIControlStateNormal];
    CGAffineTransform counterClockwise = CGAffineTransformMakeRotation(-M_PI_2);
    self.buttonBack.transform = counterClockwise;
    [self.buttonBack addTarget:self action:@selector(goBack:) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:self.buttonBack];
    // Adding MENU button
    frame = CGRectMake(0, 0, 50, 50);
    menuButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *menuImg = [UIImage imageNamed:@"button_menu.png"];
    [menuButton setImage:menuImg forState:UIControlStateNormal];
    menuButton.transform = counterClockwise;
    //[menuButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
    [menuButton addTarget:self action:@selector(goToMenu:) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:menuButton];
    // Adding COUNT label
    // These frequent view related steps should be done in Model side.
    // Count label translates the view by 35 px along x and 85px along y axis because the label is a rectangle
    frame = CGRectMake(0, 0, 120, 50);
    self.countLabel = [[UILabel alloc] initWithFrame:frame];
    [self.countLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20]];
    [self.countLabel setText:[NSString stringWithFormat:@"%@", [self.currTribe tribeName]]];
    [self.countLabel setTextColor:[UIColor whiteColor]];
    [self.countLabel setTextAlignment:NSTextAlignmentCenter];
    self.countLabel.transform = counterClockwise;
    [self.countLabel setBackgroundColor:[UIColor clearColor]];
    [self.tableView addSubview:self.countLabel];
    self.countLabel.center = topBar.center;
    
    // Adding CAPTURE button
    CGRect buttonCaptureFrame = CGRectMake(self.view.bounds.size.width - 50, 0, 50, 50);
    self.buttonCapture = [[UIButton alloc] initWithFrame:buttonCaptureFrame];
    UIImage *captureImage = [UIImage imageNamed:@"button_vybe.png"];
    [self.buttonCapture setContentMode:UIViewContentModeCenter];
    [self.buttonCapture setImage:captureImage forState:UIControlStateNormal];
    self.buttonCapture.transform = counterClockwise;
    [self.buttonCapture addTarget:self action:@selector(captureVybe:) forControlEvents:UIControlEventTouchUpInside];
    [[self tableView] addSubview:self.buttonCapture];
   
    // Adding FRIENDS button
    frame = CGRectMake(self.view.bounds.size.width - 50, self.view.bounds.size.height - 50, 50, 50);
    friendsButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *friendsImg = [UIImage imageNamed:@"button_friends.png"];
    [friendsButton setContentMode:UIViewContentModeCenter];
    [friendsButton setImage:friendsImg forState:UIControlStateNormal];
    friendsButton.transform = counterClockwise;
    //[self.tableView addSubview:friendsButton];
    
    // Adding a refresh control
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.tintColor = [UIColor whiteColor];
    [refresh addTarget:self action:@selector(refreshTribeVybes:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refresh];
    
    // Update so downloaded vybes are displayed
    //[self refreshTribeVybes:refresh];
}

/* Scroll down to the bottom to show recent vybes first */

- (void)viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
    [super viewWillAppear:animated];
    NSInteger idx = [self oldestUnwatchedVybeIn:[self.currTribe vybes]];
    if (idx < 0)
        return;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}


- (void)viewDidDisappear:(BOOL)animated {
    [[VYBMyTribeStore sharedStore] saveChanges];
    [super viewDidDisappear:animated];
}


- (void)refreshTribeVybes:(UIRefreshControl *)refresh {
    // Check for new vybes
    [[VYBMyTribeStore sharedStore] syncWithCloudForTribe:[self.currTribe tribeName] withCompletionBlock:^(NSError *err){
        if (refresh)
            [refresh endRefreshing];
        if (!err) {
            // If there is no vybe in this tribe yet
            if ([[self.currTribe vybes] count] < 1) {
                NSString *msg = @"No vybe in this tribe yet. Create the FIRST vybe!";
                UIAlertView *popUp = [[UIAlertView alloc] initWithTitle:@"" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [popUp show];
            }
            // Update so downloaded vybes are displayed
            [self.tableView reloadData];
        }
        else {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Network Temporarily Unavailable" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [av show];
        }
    }];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.currTribe vybes] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VYBVybeCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VYBVybeCell"];
    if (!cell) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"VYBVybeCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    NSString *thumbPath = [[[self.currTribe vybes] objectAtIndex:[indexPath row]] tribeThumbnailPath];
    //NSLog(@"Cell with img:%@", thumbPath);
    // Cache thumbnail images into a memory
    UIImage *thumbImg = [[VYBImageStore sharedStore] imageWithKey:thumbPath];
    if (!thumbImg) {
        thumbImg = [UIImage imageWithContentsOfFile:thumbPath];
        if (thumbImg)
            [[VYBImageStore sharedStore] setImage:thumbImg forKey:thumbPath];
    }
    // Customize cell when there is a thumb image
    [cell.thumbnailView setImage:thumbImg];
    [cell customize];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];

    [self.navigationController presentViewController:playerVC animated:NO completion:^(){
        [playerVC setVybePlaylist:[self.currTribe vybes]];
        // Here d indicated the number of downloaded vybes and n is the number of vybes including the ones to be downloaded
        [playerVC playFrom:[indexPath row]];
    }];
}

- (void)captureVybe:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
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

/**
 * Repositioning floating views during/after scroll
 **/

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {    
    CGRect frameTwo = self.buttonCapture.frame;
    frameTwo.origin.y = scrollView.contentOffset.y;
    self.buttonCapture.frame = frameTwo;
    
    CGRect frameThree = topBar.frame;
    frameThree.origin.y = scrollView.contentOffset.y;
    topBar.frame = frameThree;
    
    CGRect frameFour = friendsButton.frame;
    frameFour.origin.y = scrollView.contentOffset.y + self.view.bounds.size.height - 50;
    friendsButton.frame = frameFour;
    
    self.countLabel.center = topBar.center;
    
    [[self view] bringSubviewToFront:topBar];
    [[self view] bringSubviewToFront:self.buttonCapture];
    [[self view] bringSubviewToFront:self.countLabel];
    [[self view] bringSubviewToFront:friendsButton];
}

- (NSInteger)oldestUnwatchedVybeIn:(NSMutableArray *)vybes {
    NSInteger i = [vybes count] - 1;
    for (; i >= 0; i--) {
        VYBVybe *v = [vybes objectAtIndex:i];
        if (![v isWatched]) {
            return i;
        }
    }
    return [vybes count] - 1;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
