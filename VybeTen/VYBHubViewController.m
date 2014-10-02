
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBFreshVybeFeedFetchedFromRemoteNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    controlView.delegate = self;
    
    // Navigation bar settings
    [self.navigationItem setTitle:@"vybe"];
    
    UIBarButtonItem *captureButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_capture.png"] style:UIBarButtonItemStylePlain target:self action:@selector(captureButtonPressed:)];
    self.navigationItem.rightBarButtonItem = captureButton;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(freshVybeCountChanged) name:VYBCacheFreshVybeCountChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(freshVybeCountChanged) name:VYBFreshVybeFeedFetchedFromRemoteNotification object:nil];
    
    [self freshVybeCountChanged];
    [self getVybesByLocationAndByUser];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationItem setTitle:@"vybe"];
}

- (void)getUsersByLocation {    
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
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:VYBHubScreenVybesLoadedNotification object:nil];
            });
        }
    }];
}


- (void)getVybesByLocationAndByUser {
    [VYBUtility getVybesByLocationAndByUser:^(BOOL succeeded, NSError *error) {
        if (!error) {
            [self getUsersByLocation];
        }
    }];
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


#pragma mark - ()

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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"embedContainer"]) {
        self.swapContainerController = segue.destinationViewController;
    }
}

@end
