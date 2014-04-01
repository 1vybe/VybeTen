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

#import "VYBMyVybesViewController.h"
#import "VYBMyVybeStore.h"
#import "VYBMyTribeStore.h"
#import "VYBVybeCell.h"
#import "VYBImageStore.h"
#import "VYBPlayerViewController.h"


@implementation VYBMyVybesViewController
@synthesize buttonCapture = _buttonCapture;
@synthesize buttonBack = _buttonBack;
@synthesize bottomBar = _bottomBar;
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

    NSLog(@"[viewDidLoad]: MyVybes");
    /* Table Setup for horizontal transparent tableview */
    self.tableView.frame = CGRectMake(0, 0, self.tableView.frame.size.width, self.tableView.frame.size.height);
    // Rotate the tableView for horizontal scrolling
    /* MyVybes rotates counter clockwise where MyTribes and MyTribeVybes rotates clockwise */
    CGAffineTransform rotateTable = CGAffineTransformMakeRotation(-M_PI_2);
    self.tableView.transform = rotateTable;
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    // Remove cell separators
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView setRowHeight:200.0f];
    self.tableView.showsVerticalScrollIndicator = NO;
    UIToolbar* blurredView = [[UIToolbar alloc] initWithFrame:self.tableView.bounds];
    [blurredView setBarStyle:UIBarStyleBlack];
    [self.tableView setBackgroundView:blurredView];
    
    // Adding transparent bar at the bottom to fix buttons during scrolling
    CGRect bottomBarFrame = CGRectMake(0, self.view.bounds.size.width - 50, self.view.bounds.size.height, 50);
    self.bottomBar = [[UIView alloc] initWithFrame:bottomBarFrame];
    [self.bottomBar setBackgroundColor:[UIColor clearColor]];
    
    // Adding CAPTURE button
    CGRect buttonCaptureFrame = CGRectMake(self.view.bounds.size.height - 50, 0, 50, 50);
    self.buttonCapture = [[UIButton alloc] initWithFrame:buttonCaptureFrame];
    UIImage *captureImage = [UIImage imageNamed:@"button_vybe.png"];
    [self.buttonCapture setContentMode:UIViewContentModeCenter];
    [self.buttonCapture setImage:captureImage forState:UIControlStateNormal];
    [self.buttonCapture addTarget:self action:@selector(captureVybe:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.buttonCapture];
    // Adding BACK button
    CGRect buttonBackFrame = CGRectMake(0, 0, 50, 50);
    self.buttonBack = [[UIButton alloc] initWithFrame:buttonBackFrame];
    UIImage *backImage = [UIImage imageNamed:@"button_back.png"];
    [self.buttonBack setContentMode:UIViewContentModeCenter];
    [self.buttonBack setImage:backImage forState:UIControlStateNormal];
    [self.buttonBack addTarget:self action:@selector(goBack:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.buttonBack];
    
    CGRect frame = CGRectMake(self.view.bounds.size.width - 75, 25, 100, 50);
    self.countLabel = [[UILabel alloc] initWithFrame:frame];
    [self.countLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20]];
    [self.countLabel setText:[NSString stringWithFormat:@"MY VYBES"]];
    [self.countLabel setTextColor:[UIColor colorWithWhite:1.0 alpha:0.8]];
    [self.countLabel setTextAlignment:NSTextAlignmentCenter];
    CGAffineTransform clockwise = CGAffineTransformMakeRotation(M_PI_2);
    self.countLabel.transform = clockwise;
    [self.countLabel setBackgroundColor:[UIColor clearColor]];
    [self.tableView addSubview:self.countLabel];

    
    [[VYBMyVybeStore sharedStore] delayedUploadsBegin];
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"view did appear for MyVybesVC");
    [super viewDidAppear:animated];
    [self.navigationController.view addSubview:self.bottomBar];
    [[VYBMyVybeStore sharedStore] delayedUploadsBegin];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.bottomBar removeFromSuperview];
}


/* Scroll down to the bottom to show recent vybes first */
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSInteger idx = [[[VYBMyVybeStore sharedStore] myVybes] count] - 1;
    if (idx < 0)
        return;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
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
    NSLog(@"MyVybes cell created:%@", [vybe thumbnailPath]);
    if (!thumbImg) {
        //NSLog(@"MyVybe ThumbImg:%@", [vybe thumbnailPath]);
        thumbImg = [UIImage imageWithContentsOfFile:[vybe thumbnailPath]];
        if (thumbImg)
            [[VYBImageStore sharedStore] setImage:thumbImg forKey:[vybe thumbnailPath]];
    }
    // Customize cell
    [cell.thumbnailView setImage:thumbImg];
    [cell customizeOtherDirection];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
    [playerVC playFrom:[indexPath row]];
    [self.navigationController pushViewController:playerVC animated:NO];
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect frame = self.countLabel.frame;
    frame.origin.y = scrollView.contentOffset.y;
    self.countLabel.frame = frame;
    
    [[self view] bringSubviewToFront:self.countLabel];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self.bottomBar removeFromSuperview];
    
    // Dispose of any resources that can be recreated.
}

@end
