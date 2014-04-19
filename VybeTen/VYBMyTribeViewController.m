//
//  VYBMyTribeViewController.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 8..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBMyTribeViewController.h"
#import "VYBVybeCell.h"
#import "VYBImageStore.h"
#import "VYBMyTribeStore.h"
#import "VYBTribeVybesViewController.h"
//#import "GAI.h"
//#import "GAIDictionaryBuilder.h"
//#import "GAIFields.h"

@implementation VYBMyTribeViewController

@synthesize buttonBack = _buttonBack;
@synthesize buttonCapture = _buttonCapture;
@synthesize createButton = _createButton;
@synthesize countLabel = _countLabel;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
    }
    
    return self;
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
    
    // Adding CAPTURE button
    CGRect buttonFrame = CGRectMake(self.view.bounds.size.width - 50, 0, 50, 50);
    self.buttonCapture = [[UIButton alloc] initWithFrame:buttonFrame];
    UIImage *buttonImg = [UIImage imageNamed:@"button_vybe.png"];
    [self.buttonCapture setContentMode:UIViewContentModeCenter];
    [self.buttonCapture setImage:buttonImg forState:UIControlStateNormal];
    CGAffineTransform rotation = CGAffineTransformMakeRotation(-M_PI_2);
    self.buttonCapture.transform = rotation;
    [self.buttonCapture addTarget:self action:@selector(captureVybe:) forControlEvents:UIControlEventTouchUpInside];
    [[self tableView] addSubview:self.buttonCapture];
    // Adding BACK button
    buttonFrame = CGRectMake(self.view.bounds.size.width - 50, self.view.bounds.size.height - 50, 50, 50);
    self.buttonBack = [[UIButton alloc] initWithFrame:buttonFrame];
    buttonImg = [UIImage imageNamed:@"button_back.png"];
    [self.buttonBack setContentMode:UIViewContentModeCenter];
    [self.buttonBack setImage:buttonImg forState:UIControlStateNormal];
    self.buttonBack.transform = rotation;
    [self.buttonBack addTarget:self action:@selector(goToMenu:) forControlEvents:UIControlEventTouchUpInside];
    [[self tableView] addSubview:self.buttonBack];

    // Adding CREATE button
    buttonFrame = CGRectMake(0, 0, 50, 50);
    self.createButton = [[UILabel alloc] initWithFrame:buttonFrame];
    //buttonImg = [UIImage imageNamed:@"button_add.png"];
    //[self.createButton setContentMode:UIViewContentModeCenter];
    //[self.createButton setImage:buttonImg forState:UIControlStateNormal];
    [self.createButton setText:@"+"];
    [self.createButton setTextColor:[UIColor whiteColor]];
    [self.createButton setTextAlignment:NSTextAlignmentCenter];
    [self.createButton setFont:[UIFont fontWithName:@"Montreal-Xlight" size:40]];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(createTribe:)];
    [self.createButton addGestureRecognizer:tap];
    [self.createButton setUserInteractionEnabled:YES];
    [self.createButton setTransform:rotation];
    //[self.createButton addTarget:self action:@selector(createTribe:) forControlEvents:UIControlEventTouchUpInside];
    [self.tableView addSubview:self.createButton];

    // Adding COUNT label
    // These frequent view related steps should be done in Model side.
    // Count label translates the view by 25 px along x and 75px along y axis because the label is a rectangle
    CGRect frame = CGRectMake(-25, self.view.bounds.size.height - 75, 100, 50);
    self.countLabel = [[UILabel alloc] initWithFrame:frame];
    [self.countLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20]];
    [self.countLabel setText:[NSString stringWithFormat:@"MY TRIBES"]];
    [self.countLabel setTextColor:[UIColor colorWithWhite:1.0 alpha:0.8]];
    [self.countLabel setTextAlignment:NSTextAlignmentCenter];
    self.countLabel.transform = rotation;
    [self.countLabel setBackgroundColor:[UIColor clearColor]];
    [self.tableView addSubview:self.countLabel];

    
    // Adding a refresh control
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.tintColor = [UIColor whiteColor];
    [refresh addTarget:self action:@selector(refreshTribes:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refresh];
    
    [self refreshTribes:refresh];
}

- (void)viewDidAppear:(BOOL)animated {
    /* Google Analytics */
    /*
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker) {
        [tracker set:kGAIScreenName value:@"MyTribes Screen"];
        [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    }
    */
    [super viewDidAppear:animated];
    //[[VYBMyTribeStore sharedStore] refreshTribes];
}

- (void)refreshTribes:(UIRefreshControl *)refresh {
    [[VYBMyTribeStore sharedStore] refreshTribesWithCompletion:^(NSError *err) {
        [refresh endRefreshing];
        if (!err) {
            [self.tableView reloadData];
        }
        else {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Network Temporarily Unavailable" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [av show];
        }
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[VYBMyTribeStore sharedStore] saveChanges];
    [super viewDidDisappear:animated];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[VYBMyTribeStore sharedStore] myTribes] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VYBVybeCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VYBVybeCell"];
    if (!cell) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"VYBVybeCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    NSArray *tribes = [[VYBMyTribeStore sharedStore] myTribes];
    //NSLog(@"there are %d keys", [keys count]);
    NSString *title = [[tribes objectAtIndex:[indexPath row]] tribeName];
    [cell customizeWithTitle:title];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *tribes = [[VYBMyTribeStore sharedStore] myTribes];
    NSLog(@"there are %d keys", [tribes count]);
    VYBTribe *tribe = [tribes objectAtIndex:[indexPath row]];
    VYBTribeVybesViewController *vybesVC = [[VYBTribeVybesViewController alloc] init];
    NSLog(@"TribeVybesVC initiated for %@ Tribe", [tribe tribeName]);
    [vybesVC setCurrTribe:tribe];
    [self.navigationController pushViewController:vybesVC animated:NO];
}


- (void)captureVybe:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)goToMenu:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)createTribe:(id)sender {
    /* Report this action to Google Analytics */
    /*
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker) {
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"UIAction" action:@"buttonPress" label:@"createTribeButton" value:[NSNumber numberWithInt:7]] build]];
    }
    */
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Name your new tribe" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *tribeName = [[alertView textFieldAtIndex:0] text];
    if (buttonIndex == 1) {
        BOOL success = [[VYBMyTribeStore sharedStore] addNewTribe:tribeName];
        if (success) {
            NSString *msg = [NSString stringWithFormat:@"Awesome! Now %@ is your tribe", tribeName];
            UIAlertView *popUp = [[UIAlertView alloc] initWithTitle:@"" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [popUp show];
        } else {
            NSString *msg = @"Sorry :( That tribe name is taken";
            UIAlertView *popUp = [[UIAlertView alloc] initWithTitle:@"" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [popUp show];
        }
        [self.tableView reloadData];
    }
}


/**
 * Repositioning floating views during/after scroll
 **/

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect frame = self.buttonBack.frame;
    frame.origin.y = scrollView.contentOffset.y + self.view.bounds.size.height - 50;
    self.buttonBack.frame = frame;
    
    CGRect frameTwo = self.buttonCapture.frame;
    frameTwo.origin.y =scrollView.contentOffset.y;
    self.buttonCapture.frame = frameTwo;
    
    CGRect frameThree = self.createButton.frame;
    frameThree.origin.y = scrollView.contentOffset.y;
    self.createButton.frame = frameThree;
    
    CGRect frameFour = self.countLabel.frame;
    frameFour.origin.y = scrollView.contentOffset.y + self.view.bounds.size.height - 100;
    self.countLabel.frame = frameFour;
    
    [[self view] bringSubviewToFront:self.buttonBack];
    [[self view] bringSubviewToFront:self.buttonCapture];
    [[self view] bringSubviewToFront:self.createButton];
    [[self view] bringSubviewToFront:self.countLabel];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
