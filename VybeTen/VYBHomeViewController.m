//
//  VYBHomeViewController.m
//  VybeTen
//
//  Created by jinsuk on 6/12/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBHomeViewController.h"
#import "VYBLoginViewController.h"
#import "VYBCaptureViewController.h"
#import "VYBCache.h"
#import "VYBUtility.h"

@interface VYBHomeViewController ()

@end

@implementation VYBHomeViewController {
    NSInteger _pageIndex;
    VYBLoginViewController *logInViewController;
    VYBCaptureViewController *captureVC;
    NSMutableData *_data;
}

#pragma mark - VYBPageViewControllerDelegate

+ (VYBHomeViewController *)homeViewControllerForPageIndex:(NSInteger)pageIndex {
    if (pageIndex >= 0 && pageIndex < 3) {
        return [[self alloc] initWithPageIndex:pageIndex];
    }
    return nil;
}

- (id)initWithPageIndex:(NSInteger)pageIndex {
    self = [super init];
    if (self) {
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
    self.view.backgroundColor = [UIColor orangeColor];

    UIDevice *iphone = [UIDevice currentDevice];
    [iphone beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIDeviceOrientationDidChangeNotification object:iphone];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (![PFUser currentUser]) {
        [self presentLoginViewController];
        return;
    }
    
}

- (void)deviceOrientationChanged:(NSNotification *)note {
    UIDevice *device = [note object];
    if ( UIDeviceOrientationIsPortrait([device orientation]) ) {
        /*
         if (!overlayView) {
         UIWindow *window = self.view.window;
         overlayView = [[UIImageView alloc] initWithFrame:window.bounds];
         [overlayView setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.8f]];
         [overlayView setUserInteractionEnabled:YES];
         [overlayView setContentMode:UIViewContentModeCenter];
         [overlayView setImage:[UIImage imageNamed:@"screen_warning_rotate.png"]];
         [window addSubview:overlayView];
         }
         */
        [captureVC.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else if ( UIDeviceOrientationIsLandscape([device orientation]) ) {
        /*
         [overlayView removeFromSuperview];
         overlayView = nil;
         */
        captureVC = [[VYBCaptureViewController alloc] init];
        [self presentViewController:captureVC animated:YES completion:nil];
    }
}

- (void)presentLoginViewController {
    logInViewController = [[VYBLoginViewController alloc] init];
    [logInViewController setDelegate:self];
    [logInViewController setFields:PFLogInFieldsFacebook];
    NSArray *permissionsArray = @[ @"public_profile" ];
    [logInViewController setFacebookPermissions:permissionsArray];
    
    [self presentViewController:logInViewController animated:NO completion:nil];
}


#pragma mark - PFLoginViewControllerDelegate

- (void)logInViewController:(PFLogInViewController *)controller
               didLogInUser:(PFUser *)user {
    if (user.isNew) {
        NSLog(@"NEW User is %@", [[PFUser currentUser] username]);
    }
    else {
        NSLog(@"Returning User is %@", [[PFUser currentUser] username]);
    }
    
    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            [self facebookRequestDidLoad:result];
        } else {
            [self facebookRequestDidFailWithError:error];
        }
    }];
    
    [logInViewController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
    NSLog(@"Failed to log in: %@", error);
    [logInViewController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}



/**
 * Facebook Request methods
 **/

- (void)facebookRequestDidLoad:(id)result {
    PFUser *user = [PFUser currentUser];
    
    NSArray *data = [result objectForKey:@"data"];
    
    if (data) {
        NSMutableArray *facebookIDs = [[NSMutableArray alloc] initWithCapacity:[data count]];
        BOOL flag = YES;
        for (NSDictionary *friendData in data) {
            if (flag) {
                //NSLog(@"[f]:%@", friendData);
                flag = NO;
            }
            if (friendData[@"id"]) {
                [facebookIDs addObject:friendData[@"id"]];
            }
        }
        
        // cache friends data
        [[VYBCache sharedCache] setFacebookFriends:facebookIDs];
        
        if (!user) {
            NSLog(@"No user info is found. Forcing logging out");
            [self logOut];
        }
    } else {
        // Creating a profile
        if (user) {
            NSString *facebookName = result[@"name"];
            if (facebookName && [facebookName length] != 0) {
                [user setObject:facebookName forKey:kVYBUserDisplayNameKey];
            }
            
            NSString *facebookID = result[@"id"];
            if (facebookID && [facebookID length] != 0) {
                [user setObject:facebookID forKey:kVYBUserFacebookIDKey];
            }
            
            [user saveEventually];
            
            [self fetchCurrentUserData];
        }
        
        [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error){
            if (!error) {
                [self facebookRequestDidLoad:result];
            } else {
                [self facebookRequestDidFailWithError:error];
            }
        }];
    }
}

- (void)facebookRequestDidFailWithError:(NSError *)error {
    NSLog(@"Facebook error: %@", error);
    
    if ([PFUser currentUser]) {
        if ( [[error userInfo][@"error"][@"type"] isEqualToString:@"OAuthException"] ) {
            NSLog(@"OAuthException occured. Logging out");
            [self logOut];
        }
    }
}


#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _data = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [VYBUtility processFacebookProfilePictureData:_data];
}

- (void)refreshUserData {    
    // Refresh current user with server side data -- checks if user is still valid and so on
    [[PFUser currentUser] refreshInBackgroundWithTarget:self selector:@selector(refreshCurrentUserCallbackWithResult:error:)];
}

- (void)fetchCurrentUserData {
    // Download user's profile picture
    NSURL *profilePictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", [[PFUser currentUser] objectForKey:kVYBUserFacebookIDKey]]];
    NSURLRequest *profilePictureURLRequest = [NSURLRequest requestWithURL:profilePictureURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0f]; // Facebook profile picture cache policy: Expires in 2 weeks
    [NSURLConnection connectionWithRequest:profilePictureURLRequest delegate:self];
}

- (void)refreshCurrentUserCallbackWithResult:(PFObject *)refreshedObject error:(NSError *)error {
    // A kPFErrorObjectNotFound error on currentUser refresh signals a deleted user
    if (error && error.code == kPFErrorObjectNotFound) {
        NSLog(@"User does not exist.");
        [self logOut];
        return;
    }
    
    NSString *facebookIDKey = [[PFUser currentUser] objectForKey:kVYBUserFacebookIDKey];
    if (facebookIDKey && [facebookIDKey length] != 0) {
        // refresh friends list on each launch
        [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                [self facebookRequestDidLoad:result];
            } else {
                [self facebookRequestDidFailWithError:error];
            }
        }];
    }
    
    else {
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                [self facebookRequestDidLoad:result];
            } else {
                [self facebookRequestDidFailWithError:error];
            }
        }];
        
    }
}

- (void)logOut {
    // clear cache
    [[VYBCache sharedCache] clear];
    
    // clear NSUserDefaults
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kVYBUserDefaultsCacheFacebookFriendsKey];
    //[[NSUserDefaults standardUserDefaults] removeObjectForKey:kPAPUserDefaultsActivityFeedViewControllerLastRefreshKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Unsubscribe from push notifications by removing the user association from the current installation.
    [[PFInstallation currentInstallation] removeObjectForKey:kVYBInstallationUserKey];
    [[PFInstallation currentInstallation] saveInBackground];
    
    // Clear all caches
    [PFQuery clearAllCachedResults];
    
    [PFUser logOut];
    
    [self presentLoginViewController];
}





@end
