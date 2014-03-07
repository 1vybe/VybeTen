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
#import "VYBVybeStore.h"
#import "VYBVybeCell.h"
#import "VYBImageStore.h"
#import "VYBPlayerViewController.h"


@implementation VYBMyVybesViewController
@synthesize buttonCapture, buttonMenu;

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
    [self.tableView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.4]];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView setRowHeight:200.0f];
    self.tableView.showsVerticalScrollIndicator = NO;
    CGRect frame = self.tableView.frame;
    UIView *transView = [[UIView alloc] initWithFrame:frame];


    [self.tableView setBackgroundView:transView];
    
    // Adding capture button
    CGRect buttonCaptureFrame = CGRectMake(self.view.bounds.size.width - 48, self.view.bounds.size.height - 48, 48, 48);
    buttonCapture = [[UIButton alloc] initWithFrame:buttonCaptureFrame];
    UIImage *captureImage = [UIImage imageNamed:@"capture.png"];
    [buttonCapture setImage:captureImage forState:UIControlStateNormal];
    [buttonCapture addTarget:self action:@selector(captureVybe) forControlEvents:UIControlEventTouchUpInside];
    [[self tableView] addSubview:buttonCapture];
    // Adding menu button
    CGRect buttonMenuFrame = CGRectMake(self.view.bounds.size.width - 48, 0, 48, 48);
    buttonMenu = [[UIButton alloc] initWithFrame:buttonMenuFrame];
    UIImage *menuImage = [UIImage imageNamed:@"menu.png"];
    [buttonMenu setImage:menuImage forState:UIControlStateNormal];
    CGAffineTransform rotation = CGAffineTransformMakeRotation(-M_PI_2);
    buttonMenu.transform = rotation;
    [buttonMenu addTarget:self action:@selector(goToMenu) forControlEvents:UIControlEventTouchUpInside];
    [[self tableView] addSubview:buttonMenu];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[VYBVybeStore sharedStore] myVybes] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VYBVybeCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VYBVybeCell"];
    if (!cell) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"VYBVybeCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    VYBVybe *vybe = [[[VYBVybeStore sharedStore] myVybes] objectAtIndex:[indexPath row]];
    // Cache thumbnail images into a memory
    UIImage *thumbImg = [[VYBImageStore sharedStore] imageWithKey:[vybe getThumbnailPath]];
    if (!thumbImg) {
        thumbImg = [UIImage imageWithContentsOfFile:[vybe getThumbnailPath]];
        [[VYBImageStore sharedStore] setImage:thumbImg forKey:[vybe getThumbnailPath]];
    }
    [cell.thumbnailImageView setImage:thumbImg];
    [cell customize];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"SELECTED");
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
    [playerVC playFrom:[indexPath row]];
    [self.navigationController pushViewController:playerVC animated:NO];
}

- (void)captureVybe {
    NSLog(@"capture");
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)goToMenu {
    NSLog(@"menu");
    [self.navigationController popViewControllerAnimated:NO];
}

/**
 * Repositioning floating views during/after scroll
 **/

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect frame = buttonMenu.frame;
    frame.origin.y = scrollView.contentOffset.y;
    buttonMenu.frame = frame;
    
    CGRect frameTwo = buttonCapture.frame;
    frameTwo.origin.y =scrollView.contentOffset.y + self.view.bounds.size.height - 48;
    buttonCapture.frame = frameTwo;
    
    [[self view] bringSubviewToFront:buttonMenu];
    [[self view] bringSubviewToFront:buttonCapture];

}



@end
