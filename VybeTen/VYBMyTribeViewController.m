//
//  VYBMyTribeViewController.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 8..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBMyTribeViewController.h"


@implementation VYBMyTribeViewController
@synthesize buttonMenu = _buttonMenu;
@synthesize buttonCapture = _buttonCapture;

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
    self.buttonCapture = [[UIButton alloc] initWithFrame:buttonCaptureFrame];
    UIImage *captureImage = [UIImage imageNamed:@"capture.png"];
    [self.buttonCapture setImage:captureImage forState:UIControlStateNormal];
    [self.buttonCapture addTarget:self action:@selector(captureVybe) forControlEvents:UIControlEventTouchUpInside];
    [[self tableView] addSubview:self.buttonCapture];
    // Adding menu button
    CGRect buttonMenuFrame = CGRectMake(self.view.bounds.size.width - 48, 0, 48, 48);
    self.buttonMenu = [[UIButton alloc] initWithFrame:buttonMenuFrame];
    UIImage *menuImage = [UIImage imageNamed:@"menu.png"];
    [self.buttonMenu setImage:menuImage forState:UIControlStateNormal];
    CGAffineTransform rotation = CGAffineTransformMakeRotation(-M_PI_2);
    self.buttonMenu.transform = rotation;
    [self.buttonMenu addTarget:self action:@selector(goToMenu) forControlEvents:UIControlEventTouchUpInside];
    [[self tableView] addSubview:self.buttonMenu];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
