
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
#import "VYBPlayerViewController.h"
#import "VYBCache.h"
#import "VYBUtility.h"

@interface VYBHubViewController ()
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, weak) IBOutlet VYBHubControlView *controlView;
@property (nonatomic, weak) IBOutlet VYBWatchAllButton *watchAllButton;
@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) VYBSwapContainerViewController *swapContainerController;
@property (nonatomic) UIView *titleView;
- (IBAction)watchAllButtonPressed:(id)sender;

@end

@implementation VYBHubViewController

@synthesize controlView;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBCacheFreshVybeCountChangedNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    controlView.delegate = self;
    
    self.titleView = [[[NSBundle mainBundle] loadNibNamed:@"VYBHubTitleView" owner:nil options:nil] firstObject];
    [self.navigationItem setTitleView:self.titleView];
    if ([UIApplication sharedApplication].statusBarHidden) {
        [self.navigationItem.titleView setFrame:CGRectMake(0, 20, self.titleView.bounds.size.width, self.titleView.bounds.size.height)];
    }
    
    // Navigation bar settings
    UIBarButtonItem *captureButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_capture.png"] style:UIBarButtonItemStylePlain target:self action:@selector(captureButtonPressed:)];
    self.navigationItem.rightBarButtonItem = captureButton;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(freshVybeCountChanged) name:VYBCacheFreshVybeCountChangedNotification object:nil];
    
}

/*
- (void)getFreshVybes {
    [[VYBCache sharedCache] clearFreshVybes];
    
    NSString *functionName = @"get_fresh_vybes";
    [PFCloud callFunctionInBackground:functionName withParameters:@{} block:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (PFObject *aVybe in objects) {
                if ([aVybe isKindOfClass:[NSNull class]])
                    continue;
                [[VYBCache sharedCache] addFreshVybe:aVybe];
            }
            [self getUsersByLocation];
        }
        else {
            [self.refreshControl endRefreshing];
        }
    }];
}

- (void)getUsersByLocation {
    [[VYBCache sharedCache] clearUsersByLocation];
    
    PFQuery *query = [PFUser query];
    // 24 TTL checking
    NSDate *someTimeAgo = [[NSDate alloc] initWithTimeIntervalSinceNow:-3600 * VYBE_TTL_HOURS];
    [query whereKey:kVYBUserLastVybedTimeKey greaterThanOrEqualTo:someTimeAgo];
    [query whereKey:kVYBUserUsernameKey notEqualTo:[PFUser currentUser][kVYBUserUsernameKey]];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (PFObject *aUser in objects) {
                NSArray *token = [aUser[kVYBUserLastVybedLocationKey] componentsSeparatedByString:@","];
                if (token.count != 3)
                    continue;
                
                //NOTE: we discard the first location field (neighborhood)
                NSString *keyString = [NSString stringWithFormat:@"%@,%@", token[1], token[2]];
                [[VYBCache sharedCache] addUser:aUser forLocation:keyString];
            }
            [self getVybesByLocationAndByUser];
        } else {
            [self.refreshControl endRefreshing];
        }
    }];
}


- (void)getVybesByLocationAndByUser {
    [[VYBCache sharedCache] clearVybesByLocation];
    [[VYBCache sharedCache] clearVybesByUser];
    
    PFQuery *query = [PFQuery queryWithClassName:kVYBVybeClassKey];
    // 24 TTL checking
    NSDate *someTimeAgo = [[NSDate alloc] initWithTimeIntervalSinceNow:-3600 * VYBE_TTL_HOURS];
    [query whereKey:kVYBVybeTimestampKey greaterThanOrEqualTo:someTimeAgo];
    // Don't include urself
    [query whereKey:kVYBVybeUserKey notEqualTo:[PFUser currentUser]];
    [query whereKeyExists:kVYBVybeLocationStringKey];
    [query whereKey:kVYBVybeLocationStringKey notEqualTo:@""];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (PFObject *obj in objects) {
                NSString *locString = obj[kVYBVybeLocationStringKey];
                NSArray *token = [locString componentsSeparatedByString:@","];
                if (token.count != 3)
                    continue;
                
                //NOTE: we discard the first location field (neighborhood)
                NSString *keyString = [NSString stringWithFormat:@"%@,%@", token[1], token[2]];
                [[VYBCache sharedCache] addVybe:obj forLocation:keyString];
                [[VYBCache sharedCache] addVybe:obj forUser:obj[kVYBVybeUserKey]];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:VYBCacheFreshVybeCountChangedNotification object:nil];
            });
            
        }
        [self.refreshControl endRefreshing];
    }];
    
}
*/


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
    if ([[[VYBCache sharedCache] freshVybes] count]) {
        VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] initWithNibName:@"VYBPlayerViewController" bundle:nil];
        [playerVC setVybePlaylist:[[VYBCache sharedCache] freshVybes]];
        [self presentViewController:playerVC animated:NO completion:nil];
    }
    else {
        [VYBUtility showToastWithImage:nil title:@"You are watching from the first vybe of the day"];
    }
}


- (void)captureButtonPressed:(id)sender {
    VYBAppDelegate *appDel = (VYBAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDel moveToPage:VYBCapturePageIndex];
}

#pragma mark - VYBCacheFreshVybeCountChangedNotification

- (void)freshVybeCountChanged {
    NSInteger count = [[[VYBCache sharedCache] freshVybes] count];
    [self.watchAllButton setCounterText:[NSString stringWithFormat:@"%ld", (long)count]];
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
