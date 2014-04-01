//
//  VYBTribeVybesViewController.m
//  VybeTen
//
//  Created by jinsuk on 3/20/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBTribeVybesViewController.h"
#import "VYBVybeCell.h"
#import "VYBImageStore.h"
#import "VYBMyTribeStore.h"
#import "VYBTribePlayerViewController.h"

@implementation VYBTribeVybesViewController
@synthesize buttonBack = _buttonBack;
@synthesize buttonCapture = _buttonCapture;
@synthesize tribeName = _tribeName;
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
    
    // Adding CAPTURE button
    CGRect buttonCaptureFrame = CGRectMake(self.view.bounds.size.width - 50, 0, 50, 50);
    self.buttonCapture = [[UIButton alloc] initWithFrame:buttonCaptureFrame];
    UIImage *captureImage = [UIImage imageNamed:@"button_vybe.png"];
    [self.buttonCapture setContentMode:UIViewContentModeCenter];
    [self.buttonCapture setImage:captureImage forState:UIControlStateNormal];
    CGAffineTransform counterClockwise = CGAffineTransformMakeRotation(-M_PI_2);
    self.buttonCapture.transform = counterClockwise;
    [self.buttonCapture addTarget:self action:@selector(captureVybe:) forControlEvents:UIControlEventTouchUpInside];
    [[self tableView] addSubview:self.buttonCapture];
    // Adding BACK button
    CGRect buttonBackFrame = CGRectMake(self.view.bounds.size.width - 50, self.view.bounds.size.height - 50, 50, 50);
    self.buttonBack = [[UIButton alloc] initWithFrame:buttonBackFrame];
    UIImage *backImage = [UIImage imageNamed:@"button_back.png"];
    [self.buttonBack setContentMode:UIViewContentModeCenter];
    [self.buttonBack setImage:backImage forState:UIControlStateNormal];
    self.buttonBack.transform = counterClockwise;
    [self.buttonBack addTarget:self action:@selector(goBack:) forControlEvents:UIControlEventTouchUpInside];
    [[self tableView] addSubview:self.buttonBack];
    // Adding COUNT label
    // These frequent view related steps should be done in Model side.
    // Count label translates the view by 35 px along x and 85px along y axis because the label is a rectangle
    CGRect frame = CGRectMake(-35, self.view.bounds.size.height - 85, 120, 50);
    self.countLabel = [[UILabel alloc] initWithFrame:frame];
    [self.countLabel setFont:[UIFont fontWithName:@"Montreal-Xlight" size:20]];
    [self.countLabel setText:[NSString stringWithFormat:@"%@", self.tribeName]];
    [self.countLabel setTextColor:[UIColor colorWithWhite:1.0 alpha:0.8]];
    [self.countLabel setTextAlignment:NSTextAlignmentCenter];
    self.countLabel.transform = counterClockwise;
    [self.countLabel setBackgroundColor:[UIColor clearColor]];
    [self.tableView addSubview:self.countLabel];
    // Adding a refresh control
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.tintColor = [UIColor whiteColor];
    [refresh addTarget:self action:@selector(refreshTribeVybes:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refresh];
    
    //NSLog(@"[TribeVybesViewController]view loaded. Let's sync!");
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"#######SYNC BEGIN##########");
    UIView *view = [[UIView alloc] initWithFrame:self.view.bounds];
    [view setBackgroundColor:[UIColor redColor]];
    [self.view addSubview:view];
    [self.view setNeedsDisplay];
    BOOL success = [[VYBMyTribeStore sharedStore] syncWithCloudForTribe:self.tribeName];
    [view removeFromSuperview];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[VYBMyTribeStore sharedStore] saveChanges];
    [super viewDidDisappear:animated];
}


- (void)refreshTribeVybes:(UIRefreshControl *)refresh {
    [[VYBMyTribeStore sharedStore] syncWithCloudForTribe:self.tribeName];
    NSLog(@"synching really done");
    [self.tableView reloadData];
    [refresh endRefreshing];
    return;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[[VYBMyTribeStore sharedStore] myTribesVybes] objectForKey:self.tribeName] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VYBVybeCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VYBVybeCell"];
    if (!cell) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"VYBVybeCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    NSString *thumbPath = [[VYBMyTribeStore sharedStore] thumbPathAtIndex:[indexPath row] forTribe:self.tribeName];
    NSLog(@"Cell with img:%@", thumbPath);
    // Cache thumbnail images into a memory
    UIImage *thumbImg = [[VYBImageStore sharedStore] imageWithKey:thumbPath];
    if (!thumbImg) {
        thumbImg = [UIImage imageWithContentsOfFile:thumbPath];
        if (thumbImg)
            [[VYBImageStore sharedStore] setImage:thumbImg forKey:thumbPath];
    }
    // Customize cell
    [cell.thumbnailView setImage:thumbImg];
    [cell customize];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    VYBTribePlayerViewController *playerVC = [[VYBTribePlayerViewController alloc] init];
    [playerVC setTribeName:self.tribeName];
    [playerVC playFrom:[indexPath row]];
    [self.navigationController pushViewController:playerVC animated:NO];
}

- (void)captureVybe:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

/**
 * Repositioning floating views during/after scroll
 **/

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect frame = self.buttonBack.frame;
    frame.origin.y = scrollView.contentOffset.y + self.view.bounds.size.height - 50;
    self.buttonBack.frame = frame;
    
    CGRect frameTwo = self.buttonCapture.frame;
    frameTwo.origin.y = scrollView.contentOffset.y;
    self.buttonCapture.frame = frameTwo;
    
    CGRect frameThree = self.countLabel.frame;
    frameThree.origin.y = scrollView.contentOffset.y + self.view.bounds.size.height - 120;
    self.countLabel.frame = frameThree;
    
    [[self view] bringSubviewToFront:self.buttonBack];
    [[self view] bringSubviewToFront:self.buttonCapture];
    [[self view] bringSubviewToFront:self.countLabel];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
