//
//  VYBWelcomeViewController.m
//  VybeTen
//
//  Created by jinsuk on 5/7/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBWelcomeViewController.h"
#import "VYBAppDelegate.h"
#import "VYBConstants.h"

@implementation VYBWelcomeViewController

- (void)loadView {
    [super loadView];
    /* TODO: Loading Screen while fetching user data */
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (![PFUser currentUser]) {
        [(VYBAppDelegate *)[[UIApplication sharedApplication] delegate] presentLoginViewControllerAnimated:NO];
        return;
    }
    
    [(VYBAppDelegate *)[[UIApplication sharedApplication] delegate] fetchCurrentUserData];
    
    // Refresh current user with server side data -- checks if user is still valid and so on
    [[PFUser currentUser] refreshInBackgroundWithTarget:self selector:@selector(refreshCurrentUserCallbackWithResult:error:)];
    
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)refreshCurrentUserCallbackWithResult:(PFObject *)refreshedObject error:(NSError *)error {
    // A kPFErrorObjectNotFound error on currentUser refresh signals a deleted user
    if (error && error.code == kPFErrorObjectNotFound) {
        NSLog(@"User does not exist.");
        [(VYBAppDelegate *)[[UIApplication sharedApplication] delegate] logOut];
        return;
    }
    
    NSString *facebookIDKey = [[PFUser currentUser] objectForKey:kVYBUserFacebookIDKey];
    if (facebookIDKey && [facebookIDKey length] != 0) {
        // refresh friends list on each launch
        [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                if ([[UIApplication sharedApplication].delegate respondsToSelector:@selector(facebookRequestDidLoad:)]) {
                    [[UIApplication sharedApplication].delegate performSelector:@selector(facebookRequestDidLoad:) withObject:result];
                }
            } else {
                if ([[UIApplication sharedApplication].delegate respondsToSelector:@selector(facebookRequestDidFailWithError:)]) {
                    [[UIApplication sharedApplication].delegate performSelector:@selector(facebookRequestDidFailWithError:) withObject:error];
                }
            }
        }];
    }
    
    else {
        
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                if ([[UIApplication sharedApplication].delegate respondsToSelector:@selector(facebookRequestDidLoad:)]) {
                    [[UIApplication sharedApplication].delegate performSelector:@selector(facebookRequestDidLoad:) withObject:result];
                }
            } else {
                if ([[UIApplication sharedApplication].delegate respondsToSelector:@selector(facebookRequestDidFailWithError:)]) {
                    [[UIApplication sharedApplication].delegate performSelector:@selector(facebookRequestDidFailWithError:) withObject:error];
                }
            }
        }];
        
    }
}

@end
