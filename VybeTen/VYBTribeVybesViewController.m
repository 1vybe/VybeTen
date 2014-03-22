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
    // Rotate the tableView for horizontal scrolling
    CGAffineTransform rotateTable = CGAffineTransformMakeRotation(-M_PI_2);
    self.tableView.transform = rotateTable;
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView setRowHeight:200.0f];
    self.tableView.showsVerticalScrollIndicator = NO;
    UIToolbar* blurredView = [[UIToolbar alloc] initWithFrame:self.tableView.bounds];
    [blurredView setBarStyle:UIBarStyleBlack];
    [self.tableView setBackgroundView:blurredView];
    
    // Adding CAPTURE button
    CGRect buttonCaptureFrame = CGRectMake(6, self.view.bounds.size.height - 40, 34, 34);
    self.buttonCapture = [[UIButton alloc] initWithFrame:buttonCaptureFrame];
    UIImage *captureImage = [UIImage imageNamed:@"button_vybe.png"];
    [self.buttonCapture setImage:captureImage forState:UIControlStateNormal];
    CGAffineTransform rotation = CGAffineTransformMakeRotation(M_PI_2);
    self.buttonCapture.transform = rotation;
    [self.buttonCapture addTarget:self action:@selector(captureVybe) forControlEvents:UIControlEventTouchUpInside];
    [[self tableView] addSubview:self.buttonCapture];
    // Adding BACK button
    CGRect buttonBackFrame = CGRectMake(6, 6, 34, 34);
    self.buttonBack = [[UIButton alloc] initWithFrame:buttonBackFrame];
    UIImage *backImage = [UIImage imageNamed:@"button_back.png"];
    [self.buttonBack setImage:backImage forState:UIControlStateNormal];
    self.buttonBack.transform = rotation;
    [self.buttonBack addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [[self tableView] addSubview:self.buttonBack];
    
    [[VYBMyTribeStore sharedStore] syncWithCloudForTribe:self.tribeName];
}

/* Scroll to the bottom of table */
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSInteger idx = [[[[VYBMyTribeStore sharedStore] myTribesVybes] objectForKey:self.tribeName] count] - 1;
    if (idx < 0)
        return;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
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
    // Cache thumbnail images into a memory
    UIImage *thumbImg = [[VYBImageStore sharedStore] imageWithKey:thumbPath];
    if (!thumbImg) {
        thumbImg = [UIImage imageWithContentsOfFile:thumbPath];
        if (thumbImg)
            [[VYBImageStore sharedStore] setImage:thumbImg forKey:thumbPath];
    }
    // Customize cell
    [cell.thumbnailImageView setImage:thumbImg];
    [cell customize];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    VYBTribePlayerViewController *playerVC = [[VYBTribePlayerViewController alloc] init];
    [playerVC setTribeName:self.tribeName];
    [playerVC playFrom:[indexPath row]];
    [self.navigationController pushViewController:playerVC animated:NO];
}

- (void)captureVybe {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)goBack {
    [self.navigationController popViewControllerAnimated:YES];
}

/**
 * Repositioning floating views during/after scroll
 **/

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect frame = self.buttonBack.frame;
    frame.origin.y = scrollView.contentOffset.y;
    self.buttonBack.frame = frame;
    
    CGRect frameTwo = self.buttonCapture.frame;
    frameTwo.origin.y =scrollView.contentOffset.y + self.view.bounds.size.height - 40;
    self.buttonCapture.frame = frameTwo;
    
    [[self view] bringSubviewToFront:self.buttonBack];
    [[self view] bringSubviewToFront:self.buttonCapture];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
