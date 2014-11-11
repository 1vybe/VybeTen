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
