//
//  VYBMyVybesViewController.m
//  VybeTen
//  VYBMyVybesViewController can extend UIViewController to fix floating views(buttons) on the same position while user scrolls over its table view.
//  For the purpose of practice, however, I implemented two methods that will automatically re-position floating views after scrolling.
//
//
//  Created by jinsuk on 2/25/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBAppDelegate.h"
#import "VYBMyVybesViewController.h"
#import "VYBMyVybeStore.h"
#import "VYBMyTribeStore.h"
#import "VYBVybeCell.h"
#import "VYBImageStore.h"
#import "VYBPlayerViewController.h"
#import "VYBMenuViewController.h"
#import "VYBLoginViewController.h"
#import "VYBSignUpViewController.h"
#import "VYBConstants.h"

//#import "GAI.h"
//#import "GAIFields.h"
//#import "GAIDictionaryBuilder.h"

@implementation VYBMyVybesViewController {
    UIView *topBar;
    UIButton *menuButton;
    UIButton *friendsButton;
}
@synthesize buttonCapture = _buttonCapture;
@synthesize buttonBack = _buttonBack;
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

    /* Table Setup for horizontal transparent tableview */
    self.tableView.frame = CGRectMake(0, 0, self.tableView.frame.size.width, self.tableView.frame.size.height);
    // Rotate the tableView for horizontal scrolling
    /* MyVybes rotates counter clockwise where MyTribes and MyTribeVybes rotates clockwise */
    CGAffineTransform rotateTable = CGAffineTransformMakeRotation(M_PI_2);
    self.tableView.transform = rotateTable;
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    // Remove cell separators
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
    //[topBar addSubview:self.buttonBack];
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
    frame = CGRectMake(0, 0, 200, 50);
    self.countLabel = [[UILabel alloc] initWithFrame:frame];
    [self.countLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20]];
    [self.countLabel setTextColor:[UIColor whiteColor]];
    [self.countLabel setTextAlignment:NSTextAlignmentCenter];
    self.countLabel.transform = counterClockwise;
    [self.countLabel setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.countLabel];
    self.countLabel.center = topBar.center;
    NSString *displayName = [[PFUser currentUser] objectForKey:kVYBUserDisplayNameKey];
    [self.countLabel setText:displayName];
    
    // Adding CAPTURE button
    CGRect buttonCaptureFrame = CGRectMake(self.view.bounds.size.width - 50, 0, 50, 50);
    self.buttonCapture = [[UIButton alloc] initWithFrame:buttonCaptureFrame];
    UIImage *captureImage = [UIImage imageNamed:@"button_vybe.png"];
    [self.buttonCapture setContentMode:UIViewContentModeCenter];
    [self.buttonCapture setImage:captureImage forState:UIControlStateNormal];
    self.buttonCapture.transform = counterClockwise;
    [self.buttonCapture addTarget:self action:@selector(captureVybe:) forControlEvents:UIControlEventTouchUpInside];
    [[self tableView] addSubview:self.buttonCapture];
    
    /* TODO: This should actually be friends button but for now it logs out a user */
    // Adding FRIENDS button
    frame = CGRectMake(self.view.bounds.size.width - 50, self.view.bounds.size.height - 50, 50, 50);
    friendsButton = [[UIButton alloc] initWithFrame:frame];
    UIImage *friendsImg = [UIImage imageNamed:@"button_friends.png"];
    [friendsButton setContentMode:UIViewContentModeCenter];
    [friendsButton setImage:friendsImg forState:UIControlStateNormal];
    friendsButton.transform = counterClockwise;
    [friendsButton addTarget:self action:@selector(logOut:) forControlEvents:UIControlEventTouchUpInside];
    [self.tableView addSubview:friendsButton];


    
    [[VYBMyVybeStore sharedStore] delayedUploadsBegin];
}

- (void)viewDidAppear:(BOOL)animated {
    /* Google Analytics */
    /*
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker) {
        [tracker set:kGAIScreenName value:@"MyVybes Screen"];
        [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    }
    */
    [super viewDidAppear:animated];
    [[VYBMyVybeStore sharedStore] delayedUploadsBegin];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[VYBMyVybeStore sharedStore] myVybes] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VYBVybeCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VYBVybeCell"];
    if (!cell) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"VYBVybeCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    VYBVybe *vybe = [[[VYBMyVybeStore sharedStore] myVybes] objectAtIndex:[indexPath row]];
    // Cache thumbnail images into a memory
    UIImage *thumbImg = [[VYBImageStore sharedStore] imageWithKey:[vybe thumbnailPath]];
    if (!thumbImg) {
        //NSLog(@"MyVybe ThumbImg:%@", [vybe thumbnailPath]);
        thumbImg = [UIImage imageWithContentsOfFile:[vybe thumbnailPath]];
        if (thumbImg)
            [[VYBImageStore sharedStore] setImage:thumbImg forKey:[vybe thumbnailPath]];
    }
    // Customize cell
    [cell.thumbnailView setImage:thumbImg];
    [cell customize];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
    [playerVC setVybePlaylist:[[VYBMyVybeStore sharedStore] myVybes]];
    [playerVC playFrom:[indexPath row]];
    [self.navigationController presentViewController:playerVC animated:NO completion:nil];
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        VYBVybe *vybe = [[[VYBMyVybeStore sharedStore] myVybes] objectAtIndex:[indexPath row]];
        BOOL success = [[VYBMyVybeStore sharedStore] removeVybe:vybe];
        if (!success) {
            NSLog(@"removing failed");
            return;
        }
        
        NSLog(@"Deleting Cell");
        
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        [self.tableView reloadData];
    }
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return YES;
}


- (void)captureVybe:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)logOut:(id)sender {
    [(VYBAppDelegate *)[[UIApplication sharedApplication] delegate] logOut];
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect frame = topBar.frame;
    frame.origin.y = scrollView.contentOffset.y;
    topBar.frame = frame;
    
    frame = friendsButton.frame;
    frame.origin.y = scrollView.contentOffset.y + self.view.bounds.size.height - 50;
    friendsButton.frame = frame;
    
    frame = self.buttonCapture.frame;
    frame.origin.y = scrollView.contentOffset.y;
    self.buttonCapture.frame = frame;
    
    self.countLabel.center = topBar.center;

    [self.view bringSubviewToFront:topBar];
    [self.view bringSubviewToFront:friendsButton];
    [self.view bringSubviewToFront:self.buttonCapture];
    [self.view bringSubviewToFront:self.countLabel];
}

@end
