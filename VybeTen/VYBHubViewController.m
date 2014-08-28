//
//  VYBHubViewController.m
//  VybeTen
//
//  Created by jinsuk on 8/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBHubViewController.h"
#import "VYBSwapContainerViewController.h"

@interface VYBHubViewController ()
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISearchDisplayController *searchDisplay;

@property (nonatomic, strong) IBOutlet UIView *controlView;
@property (nonatomic, strong) IBOutlet UIButton *locationButton;
@property (nonatomic, strong) IBOutlet UIButton *followingButton;
@property (nonatomic, weak) VYBSwapContainerViewController *swapContainerController;

- (IBAction)locationButtonPressed:(id)sender;
- (IBAction)followingButtonPressed:(id)sender;


@end

@implementation VYBHubViewController

@synthesize controlView, followingButton, locationButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [locationButton setSelected:YES];
    
    /*
    self.navigationItem.hidesBackButton = YES;
    
    UIBarButtonItem *captureButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_capture.png"] style:UIBarButtonItemStylePlain target:self action:@selector(captureButtonPressed:)];
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


/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSArray *location = self.sections.allKeys[section];
    NSArray *arr = self.sections[location];

    return [NSString stringWithFormat:@"%@  [%d]", location, (int)arr.count];
}
*/

/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)allButtonItemPressed:(id)sender {
    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
    [self.navigationController pushViewController:playerVC animated:NO];
}
 
 - (void)searchButtonPressed:(id)sender {
 self.searchBar.hidden = NO;
 [self.searchBar becomeFirstResponder];
 }
 
 - (void)captureButtonPressed:(id)sender {
 VYBAppDelegate *appDel = (VYBAppDelegate *)[UIApplication sharedApplication].delegate;
 [appDel moveToPage:VYBCapturePageIndex];
 }

 */


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
