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
#import "VYBVybeCell.h"
#import "VYBImageStore.h"
#import "VYBPlayerViewController.h"


@implementation VYBMyVybesViewController
@synthesize buttonCapture = _buttonCapture;
@synthesize buttonMenu = _buttonMenu;

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
    //NSLog(@"[viewDidLoad]: MyVybes");
    
    /* Table Setup for horizontal transparent tableview */
    self.tableView.frame = CGRectMake(0, 0, self.tableView.frame.size.width, self.tableView.frame.size.height);
    // Rotate the tableView for horizontal scrolling
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
    
    // Adding CAPTURE button
    CGRect buttonCaptureFrame = CGRectMake(6, self.view.bounds.size.height - 40, 34, 34);
    self.buttonCapture = [[UIButton alloc] initWithFrame:buttonCaptureFrame];
    UIImage *captureImage = [UIImage imageNamed:@"button_vybe.png"];
    [self.buttonCapture setImage:captureImage forState:UIControlStateNormal];
    CGAffineTransform rotation = CGAffineTransformMakeRotation(M_PI_2);
    self.buttonCapture.transform = rotation;
    [self.buttonCapture addTarget:self action:@selector(captureVybe) forControlEvents:UIControlEventTouchUpInside];
    [[self tableView] addSubview:self.buttonCapture];
    // Adding MENU button
    CGRect buttonMenuFrame = CGRectMake(6, 6, 34, 34);
    self.buttonMenu = [[UIButton alloc] initWithFrame:buttonMenuFrame];
    UIImage *menuImage = [UIImage imageNamed:@"button_menu.png"];
    [self.buttonMenu setImage:menuImage forState:UIControlStateNormal];
    self.buttonMenu.transform = rotation;
    [self.buttonMenu addTarget:self action:@selector(goToMenu) forControlEvents:UIControlEventTouchUpInside];
    [[self tableView] addSubview:self.buttonMenu];
    
    [[VYBMyVybeStore sharedStore] delayedUploadsBegin];
}

- (void)viewDidAppear:(BOOL)animated {
    //NSLog(@"view did appear for MyVybesVC");
    [super viewDidAppear:animated];
    [[VYBMyVybeStore sharedStore] delayedUploadsBegin];
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
    if (!thumbImg) {
        //NSLog(@"MyVybe ThumbImg:%@", [vybe thumbnailPath]);
        thumbImg = [UIImage imageWithContentsOfFile:[vybe thumbnailPath]];
        if (thumbImg)
            [[VYBImageStore sharedStore] setImage:thumbImg forKey:[vybe thumbnailPath]];
    }
    // Customize cell
    [cell.thumbnailImageView setImage:thumbImg];
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
        NSIndexPath *firstRow = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationFade];
        if (firstRow)
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:firstRow, nil] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    }
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return YES;
}


- (void)captureVybe {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)goToMenu {
    [self.navigationController popViewControllerAnimated:NO];
}

/**
 * Repositioning floating views during/after scroll
 **/

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    //NSLog(@"[scrollViewDidScroll] MyVybes");
    CGRect frame = self.buttonMenu.frame;
    frame.origin.y = scrollView.contentOffset.y;
    
    self.buttonMenu.frame = frame;
    
    CGRect frameTwo = self.buttonCapture.frame;
    frameTwo.origin.y = scrollView.contentOffset.y + self.view.bounds.size.height - 40;
    self.buttonCapture.frame = frameTwo;
    
    [[self view] bringSubviewToFront:self.buttonMenu];
    [[self view] bringSubviewToFront:self.buttonCapture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
