
//
//  VYBHubViewController.m
//  VybeTen
//
//  Created by jinsuk on 8/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <MBProgressHUD/MBProgressHUD.h>
#import "VYBHubViewController.h"
#import "VYBSwapContainerViewController.h"
#import "VYBHubControlView.h"
#import "VYBPlayerControlViewController.h"
#import "VYBCache.h"
#import "VYBUtility.h"

@interface VYBHubViewController ()
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, weak) VYBSwapContainerViewController *swapContainerController;
@end

@implementation VYBHubViewController {
    NSInteger _pageIndex;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBCacheFreshVybeCountChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VYBFreshVybeFeedFetchedFromRemoteNotification object:nil];
}

- (id)initWithPageIndex:(NSInteger)pageIndex {
    self = [super init];
    if (self) {
        if (pageIndex != VYBHubPageIndex)
            return nil;
        
        _pageIndex = pageIndex;
    }
    return self;
}

- (NSInteger)pageIndex {
    return _pageIndex;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    PFQuery *query = [PFQuery queryWithClassName:kVYBVybeClassKey];
    [query whereKeyExists:kVYBVybeLocationStringKey];
    [query orderByDescending:kVYBVybeTimestampKey];
    [query setLimit:50];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if (objects.count > 0) {
                VYBPlayerControlViewController *playerController = [[VYBPlayerControlViewController alloc] init];
                [playerController setVybePlaylist:objects];
                [self presentViewController:playerController animated:YES completion:^{
                    [playerController beginPlayingFrom:0];
                }];
            }
        }
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }];
    
}

#pragma mark - DeviceOrientation

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Status Bar

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark - ()

@end
