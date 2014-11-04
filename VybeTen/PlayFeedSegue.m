//
//  PlayFeedSegue.m
//  VybeTen
//
//  Created by jinsuk on 11/2/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "PlayFeedSegue.h"
#import "VYBPlayerViewController.h"
#import "VYBUtility.h"
#import "VYBCache.h"

@implementation PlayFeedSegue

- (void)perform {
    VYBPlayerViewController *player = (VYBPlayerViewController *)self.destinationViewController;
    [self.sourceViewController presentViewController:player animated:YES completion:^{
        [VYBUtility fetchFreshVybeFeedWithCompletion:^(BOOL succeeded, NSError *error) {
            if (!error) {

            }
        }];
    }];
}

@end
