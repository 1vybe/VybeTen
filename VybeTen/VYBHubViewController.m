
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
@property (nonatomic, strong) VYBHubControlView *controlView;

@property (nonatomic, strong) IBOutlet UIButton *locationButton;
@property (nonatomic, strong) IBOutlet UIButton *followingButton;
@property (nonatomic, strong) IBOutlet VYBWatchAllButton *watchAllButton;
@property (nonatomic, weak) VYBSwapContainerViewController *swapContainerController;

- (IBAction)locationButtonPressed:(id)sender;
- (IBAction)followingButtonPressed:(id)sender;
- (IBAction)watchAllButtonPressed:(id)sender;

@end

@implementation VYBHubViewController

@synthesize controlView, followingButton, locationButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Adding a custom view from xib for CONTROL
    self.controlView = [[[NSBundle mainBundle] loadNibNamed:@"VYBHubControlView" owner:self options:nil] firstObject];
    [self.controlView setFrame:CGRectMake(0, 44, self.view.bounds.size.width, 44)];
    [self.view addSubview:self.controlView];
    
    [locationButton setSelected:YES];
    
    // Navigation bar settings
    UIBarButtonItem *captureButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_capture.png"] style:UIBarButtonItemStylePlain target:self action:@selector(captureButtonPressed:)];
    self.navigationItem.rightBarButtonItem = captureButton;
    
    UIImageView *imageView = [[[NSBundle mainBundle] loadNibNamed:@"VYBTitleView" owner:nil options:nil] firstObject];
    self.navigationItem.titleView = imageView;
    
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
    

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"embedContainer"]) {
        self.swapContainerController = segue.destinationViewController;
    }
}

- (IBAction)locationButtonPressed:(id)sender
{
    if (!locationButton.selected) {
        [locationButton setSelected:YES];
        [followingButton setSelected:NO];
        [self.swapContainerController swapViewControllers];
    }
}

- (IBAction)followingButtonPressed:(id)sender {
    if (!followingButton.selected) {
        [followingButton setSelected:YES];
        [locationButton setSelected:NO];
        [self.swapContainerController swapViewControllers];
    }
}

- (IBAction)watchAllButtonPressed:(id)sender {
    id currentVC = [self.swapContainerController currentViewController];
    if (currentVC && [currentVC respondsToSelector:@selector(watchAll)]) {
        [currentVC performSelector:@selector(watchAll) withObject:nil];
    }
}


- (void)captureButtonPressed:(id)sender {
    VYBAppDelegate *appDel = (VYBAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDel moveToPage:VYBCapturePageIndex];
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
