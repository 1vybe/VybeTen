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

#pragma mark - Lifecycle

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
        
        // Refresh current user with server side data -- checks if user is still valid and so on
        [[PFUser currentUser] fetchInBackgroundWithTarget:self selector:@selector(refreshCurrentUserCallbackWithResult:error:)];
        
        // GA stuff - Setting User ID
        id tracker = [[GAI sharedInstance] defaultTracker];
        if (tracker) {
            [tracker set:@"&uid" value:[PFUser currentUser].username];
            [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"UX"
                                                                  action:@"User Logged In"
                                                                   label:nil
                                                                   value:nil] build]];
            // Setting User Group
            PFObject *tribe = [[PFUser currentUser] objectForKey:kVYBUserTribeKey];
            [tribe fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if (!error) {
                    NSString *tribeName = @"Beta Users";
                    if ( [object[kVYBTribeNameKey] isEqualToString:@"Founders"] ) {
                        tribeName = @"Founders";
                    }
                    // GA stuff - User Group Dimension
                    [[GAI sharedInstance].defaultTracker set:[GAIFields customDimensionForIndex:2] value:tribeName];
                }
            }];

        }
    }   
}

#pragma mark - Private

- (void)refreshCurrentUserCallbackWithResult:(PFObject *)refreshedObject error:(NSError *)error {
    // A kPFErrorObjectNotFound error on currentUser refresh signals a deleted user
    if (error && error.code == kPFErrorObjectNotFound) {
        NSLog(@"User does not exist.");
        [(VYBAppDelegate*)[[UIApplication sharedApplication] delegate] logOut];
        return;
    }
    // fetch fresh contents for acknowledged user
    else {        
        [[VYBMyVybeStore sharedStore] startUploadingOldVybes];
    }
}

@end
