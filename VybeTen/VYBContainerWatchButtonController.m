//
//  VYBContainerWatchButtonController.m
//  VybeTen
//
//  Created by jinsuk on 9/9/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBContainerWatchButtonController.h"
#import "VYBUsersTableViewController.h"
#import "VYBPlayerViewController.h"
#import "VYBCache.h"
#import "VYBWatchAllButton.h"

@interface VYBContainerWatchButtonController ()
@property (nonatomic, weak) IBOutlet VYBWatchAllButton *watchAllButton;
- (IBAction)watchAllButtonPressed:(id)sender;
@end

@implementation VYBContainerWatchButtonController {
    UIImageView *countryFlagImageView;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [countryFlagImageView removeFromSuperview];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    
    NSString *cityName = [self.locationKey componentsSeparatedByString:@","][0];
    self.navigationItem.title = cityName;
    
    NSString *countryCode = [self.locationKey componentsSeparatedByString:@","][1];
    // NOTE: This assumes that the navigation bar height is 44pt
    countryFlagImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 40 - 10, 2, 40, 40)];
    [countryFlagImageView setImage:[UIImage imageNamed:countryCode]];
    [countryFlagImageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.navigationController.navigationBar addSubview:countryFlagImageView];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"embedUsersTable"]) {
        self.embeddedController = segue.destinationViewController;
        self.embeddedController.delegate = self;
        [self.embeddedController setLocationKey:self.locationKey];
    }
}

- (IBAction)watchAllButtonPressed:(id)sender {
    NSArray *playList = self.embeddedController.freshVybes;
    if (playList && playList.count > 0) {
        VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] initWithNibName:@"VYBPlayerViewController" bundle:nil];
        [playerVC setVybePlaylist:playList];
        [self presentViewController:playerVC animated:NO completion:nil];
    }
}

- (void)freshVybeCountChanged {
    [self.watchAllButton setCounterText:[NSString stringWithFormat:@"%ld", (long)self.embeddedController.freshVybes.count]];
}


@end
