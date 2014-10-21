//
//  VYBWelcomeViewController.m
//  VybeTen
//
//  Created by Mohammed Tangestani on 2014-10-08.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBWelcomeViewController.h"
#import "VYBAppDelegate.h"
#import "VYBUtility.h"

@implementation VYBWelcomeViewController


#pragma mark - UIViewController
- (void)loadView {
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    [backgroundImageView setImage:[UIImage imageNamed:@"Default.png"]];
    self.view = backgroundImageView;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // If not logged in, present login view controller
    if (![PFUser currentUser]) {
        [(VYBAppDelegate*)[[UIApplication sharedApplication] delegate] presentFirstPage];
        return;
    } else {
        [(VYBAppDelegate*)[[UIApplication sharedApplication] delegate] proceedToMainInterface];
    }
    
    // Refresh current user with server side data -- checks if user is still valid and so on
    [[PFUser currentUser] fetchInBackgroundWithTarget:self selector:@selector(refreshCurrentUserCallbackWithResult:error:)];
    [VYBUtility fetchFreshVybeFeedWithCompletion:nil];
}


#pragma mark - ()

- (void)refreshCurrentUserCallbackWithResult:(PFObject *)refreshedObject error:(NSError *)error {
    // A kPFErrorObjectNotFound error on currentUser refresh signals a deleted user
    if (error && error.code == kPFErrorObjectNotFound) {
        NSLog(@"User does not exist.");
        [(VYBAppDelegate*)[[UIApplication sharedApplication] delegate] logOut];
        return;
    }
    
//    // Check if user is missing a Facebook ID
//    if ([PAPUtility userHasValidFacebookData:[PFUser currentUser]]) {
//        // User has Facebook ID.
//        
//        // refresh Facebook friends on each launch
//        [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
//            if (!error) {
//                if ([[UIApplication sharedApplication].delegate respondsToSelector:@selector(facebookRequestDidLoad:)]) {
//                    [[UIApplication sharedApplication].delegate performSelector:@selector(facebookRequestDidLoad:) withObject:result];
//                }
//            } else {
//                if ([[UIApplication sharedApplication].delegate respondsToSelector:@selector(facebookRequestDidFailWithError:)]) {
//                    [[UIApplication sharedApplication].delegate performSelector:@selector(facebookRequestDidFailWithError:) withObject:error];
//                }
//            }
//        }];
//    } else {
//        NSLog(@"Current user is missing their Facebook ID");
//        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
//            if (!error) {
//                if ([[UIApplication sharedApplication].delegate respondsToSelector:@selector(facebookRequestDidLoad:)]) {
//                    [[UIApplication sharedApplication].delegate performSelector:@selector(facebookRequestDidLoad:) withObject:result];
//                }
//            } else {
//                if ([[UIApplication sharedApplication].delegate respondsToSelector:@selector(facebookRequestDidFailWithError:)]) {
//                    [[UIApplication sharedApplication].delegate performSelector:@selector(facebookRequestDidFailWithError:) withObject:error];
//                }
//            }
//        }];
//    }
}

@end
