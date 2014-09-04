
//
//  VYBHubViewController.m
//  VybeTen
//
//  Created by jinsuk on 8/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBHubViewController.h"
#import "VYBSwapContainerViewController.h"
#import "VYBHubControlView.h"
#import "VYBAppDelegate.h"
#import "VYBWatchAllButton.h"

@interface VYBHubViewController ()
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISearchDisplayController *searchDisplay;
@property (nonatomic, strong) IBOutlet VYBHubControlView *controlView;
@property (nonatomic, strong) IBOutlet VYBWatchAllButton *watchAllButton;
@property (nonatomic, weak) VYBSwapContainerViewController *swapContainerController;
@property (nonatomic) UIView *titleView;
- (IBAction)watchAllButtonPressed:(id)sender;

@end

@implementation VYBHubViewController

@synthesize controlView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    controlView.delegate = self;
    
    self.titleView = [[[NSBundle mainBundle] loadNibNamed:@"VYBHubTitleView" owner:nil options:nil] firstObject];
    [self.navigationItem.titleView setFrame:CGRectMake(0, 0, 92, 44)];

    [self.navigationController.navigationBar addSubview:self.titleView];
    
    // Navigation bar settings
    UIBarButtonItem *captureButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_capture.png"] style:UIBarButtonItemStylePlain target:self action:@selector(captureButtonPressed:)];
    self.navigationItem.rightBarButtonItem = captureButton;

    
    /*
    self.navigationItem.hidesBackButton = YES;
    

    UIBarButtonItem *playAllButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(allButtonItemPressed:)];
    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchButtonPressed:)];
    self.navigationItem.rightBarButtonItems = @[captureButton, playAllButton];
    
    self.searchBar = [[UISearchBar alloc] init];
    [self.searchBar sizeToFit];
    [self.view addSubview:self.searchBar];
    self.searchBar.hidden = YES;
    //self.tableView.tableHeaderView = self.searchBar;
    
    self.searchDisplay = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    */
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.titleView.hidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.titleView.hidden = YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"embedContainer"]) {
        self.swapContainerController = segue.destinationViewController;
    }
}

- (void)locationButtonPressed:(id)sender {
    [self.swapContainerController swapViewControllers];

}

- (void)followingButtonPressed:(id)sender {
    [self.swapContainerController swapViewControllers];

}

- (IBAction)watchAllButtonPressed:(id)sender {
    id currentVC = [self.swapContainerController currentViewController];
    if (currentVC && [currentVC respondsToSelector:@selector(watchAll)]) {
        [currentVC performSelector:@selector(watchAll) withObject:nil];
    }
}

- (void)setWatchAllButtonCount:(NSInteger)count {
    [self.watchAllButton setCounterText:[NSString stringWithFormat:@"%ld", count]];
}



- (void)captureButtonPressed:(id)sender {
    VYBAppDelegate *appDel = (VYBAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDel moveToPage:VYBCapturePageIndex];
}

#pragma mark - Child View Controllers delegate

- (void)scrollViewBeganDragging:(UIScrollView *)scrollView {
    CGPoint translation = [scrollView.panGestureRecognizer translationInView:scrollView.superview];
    
    if(translation.y > 0)
    {
        // react to dragging down (scroll up), shrink WATCH button
        [self.watchAllButton expand];
    } else
    {
        // react to dragging up (scroll down)
        [self.watchAllButton shrink];
    }
}

#pragma mark - DeviceOrientation

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
