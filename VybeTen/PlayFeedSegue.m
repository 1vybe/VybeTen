//
//  PlayFeedSegue.m
//  VybeTen
//
//  Created by jinsuk on 11/2/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "PlayFeedSegue.h"
#import "VYBPlayerControlViewController.h"
#import "VYBCache.h"

@implementation PlayFeedSegue

- (void)perform {
    VYBPlayerControlViewController *player = (VYBPlayerControlViewController *)self.destinationViewController;
    [self.sourceViewController presentViewController:player animated:YES completion:^{
        NSArray *freshContents = [[VYBCache sharedCache] freshVybes];
        if (freshContents && freshContents.count > 0) {
            [player playVybes:freshContents];
        }
    }];
}

@end
