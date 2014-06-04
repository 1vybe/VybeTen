//
//  VYBAppDelegate.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 19..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "VYBAppDelegate.h"
#import "VYBWelcomeViewController.h"
#import "VYBLoginViewController.h"
#import "VYBSignUpViewController.h"
#import "VYBCaptureViewController.h"
#import "VYBTribesViewController.h"
#import "VYBFriendsViewController.h"
#import "VYBMyVybeStore.h"
#import "VYBMyTribeStore.h"
#import "VYBMenuViewController.h"
#import "VYBConstants.h"
#import "VYBCache.h"
#import "VYBUtility.h"
#import <HockeySDK/HockeySDK.h>
#import "Reachability.h"

@interface VYBAppDelegate () {
    NSMutableData *_data;
}

@property (nonatomic, strong) Reachability *hostReach;
@property (nonatomic, strong) Reachability *internetReach;
@property (nonatomic, strong) Reachability *wifiReach;

@end

@implementation VYBAppDelegate

@synthesize networkStatus;
@synthesize hostReach;
@synthesize internetReach;
@synthesize wifiReach;
@synthesize pageController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Use Reachability to monitor connectivity
    [self monitorReachability];

    /* HockeyApp Initilization */
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:HOCKEY_APP_ID];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
    
    // Parse Initialization
    [Parse setApplicationId:@"m5Im7uDcY5rieEbPyzRfV2Dq6YegS3kAQwxiDMFZ"
                  clientKey:@"WLqeqlf4qVVk5jF6yHSWGxw3UzUQwUtmAk9vCPfB"];
    
    // Parse Analaytics
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    // Push Notification Initialization
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
     UIRemoteNotificationTypeAlert|
     UIRemoteNotificationTypeSound];
    
    // Facebook PFUSer Settings
    [PFFacebookUtils initializeFacebook];
    
    // Twitter PFUser Settings
    [PFTwitterUtils initializeWithConsumerKey:@"JLCtQQcGYntiTy0giykRwFzDH"
                               consumerSecret:@"f778KywZHkqURPVirTMdANKxnaIg6dzKUAkqNeHe3sR9U794qn"];

    // Clearing Push-noti Badge number
    if (application.applicationIconBadgeNumber != 0) {
        application.applicationIconBadgeNumber = 0;
        [[PFInstallation currentInstallation] saveInBackground];
    }
    
    // Access Control
    PFACL *defaultACL = [PFACL ACL];
    // Enable public read access by default, with any newly created PFObjects belonging to the current user
    [defaultACL setPublicReadAccess:YES];
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];

    /*
    pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationVertical options:nil];
    pageController.dataSource = self;
    VYBMenuViewController *menuVC = [[VYBMenuViewController alloc] init];
    UINavigationController *pageZero = [[UINavigationController alloc] initWithRootViewController:menuVC];
    [pageZero.navigationBar setHidden:YES];
    [pageZero pushViewController:[VYBTribesViewController tribesViewControllerForPageIndex:0] animated:NO];
    [pageZero pushViewController:self.welcomeViewController animated:NO];
    pageZero.modalPresentationStyle = UIModalPresentationCurrentContext;
    [pageController setViewControllers:@[pageZero] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    */
    
    VYBMenuViewController *menuVC = [[VYBMenuViewController alloc] init];
    self.welcomeViewController = [[VYBWelcomeViewController alloc] init];
    self.navController = [[UINavigationController alloc] initWithRootViewController:menuVC];
    [self.navController pushViewController:[VYBTribesViewController tribesViewControllerForPageIndex:0] animated:NO];
    [self.navController pushViewController:self.welcomeViewController animated:NO];
    [self.navController.navigationBar setHidden:YES];

    [self.window setRootViewController:self.navController];
    self.window.backgroundColor = [UIColor blackColor];
    [self.window makeKeyAndVisible];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    //[self handlePush:launchOptions];
    
    return YES;
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(id)viewController {
    if ( [viewController isMemberOfClass:[UINavigationController class]] ) {
        viewController = [[(UINavigationController *)viewController viewControllers] firstObject];
    }
    NSInteger idx = [viewController pageIndex] - 1;
    if (idx == 0) {
        UINavigationController *pageZero = [[UINavigationController alloc] initWithRootViewController:[VYBTribesViewController tribesViewControllerForPageIndex:0]];
        [pageZero.navigationBar setHidden:YES];
        pageZero.modalPresentationStyle = UIModalPresentationCurrentContext;
        
        return pageZero;
    }
    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(id)viewController {
    if ( [viewController isMemberOfClass:[UINavigationController class]] ) {
        viewController = [[(UINavigationController *)viewController viewControllers] firstObject];
    }
    NSInteger idx = [viewController pageIndex] + 1;
    if (idx == 1) {
        return [VYBCaptureViewController captureViewControllerForPageIndex:1];
    }
    return nil;
}




- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    BOOL success = [[VYBMyVybeStore sharedStore] saveChanges];
    if (success)
        NSLog(@"Vybe put to sleep. My vybes are saved. :)");
    else
        NSLog(@"Vybe put to sleep. My vybes will be lost. :(");
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    BOOL success = [[VYBMyVybeStore sharedStore] saveChanges];
    if (success)
        NSLog(@"Vybe terminated. My vybes are saved. :)");
    else
        NSLog(@"Vybe terminated. My vybes will be lost. :(");
}



- (void)presentLoginViewController {
    [self presentLoginViewControllerAnimated:YES];
}

- (void)presentLoginViewControllerAnimated:(BOOL)animated {
    VYBLoginViewController *logInViewController = [[VYBLoginViewController alloc] init];
    [logInViewController setDelegate:self];
    [logInViewController setFields:PFLogInFieldsFacebook];
    NSArray *permissionsArray = @[ @"public_profile" ];
    [logInViewController setFacebookPermissions:permissionsArray];
    
    [self.welcomeViewController presentViewController:logInViewController animated:NO completion:nil];
}

- (void)fetchCurrentUserData {
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
     UIRemoteNotificationTypeAlert|
     UIRemoteNotificationTypeSound];
    
    // Download user's profile picture
    NSURL *profilePictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", [[PFUser currentUser] objectForKey:kVYBUserFacebookIDKey]]];
    NSURLRequest *profilePictureURLRequest = [NSURLRequest requestWithURL:profilePictureURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0f]; // Facebook profile picture cache policy: Expires in 2 weeks
    [NSURLConnection connectionWithRequest:profilePictureURLRequest delegate:self];
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
    
    [self.navController popToRootViewControllerAnimated:NO];
    self.welcomeViewController = [[VYBWelcomeViewController alloc] init];
    [self.navController pushViewController:self.welcomeViewController animated:NO];

    
    [self presentLoginViewControllerAnimated:NO];
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
    
    [self.navController popToRootViewControllerAnimated:NO];
    [self.welcomeViewController dismissViewControllerAnimated:NO completion:nil];
}

- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
    NSLog(@"Failed to log in: %@", error);
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


/**
 * PFPush Settigs 
 **/

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if (application.applicationIconBadgeNumber != 0) {
        application.applicationIconBadgeNumber = 0;
    }
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	if (error.code != 3010) { // 3010 is for the iPhone Simulator
        NSLog(@"Application failed to register for push notifications: %@", error);
	}
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    /* TODO: Update Badge Number */
    if ([PFUser currentUser]) {
        
    }
    
    //[PFPush handlePush:userInfo];
}


/**
 * PFUser Session Settings (Facebook)
 **/

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                        withSession:[PFFacebookUtils session]];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // TODO: Update Badge Number
    
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
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

#pragma mark - AppDelegate

- (BOOL)isParseReachable {
    return self.networkStatus != NotReachable;
}

#pragma mark - ()

- (void)monitorReachability {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    self.hostReach = [Reachability reachabilityWithHostName: @"api.parse.com"];
    [self.hostReach startNotifier];
    
    self.internetReach = [Reachability reachabilityForInternetConnection];
    [self.internetReach startNotifier];
    
    self.wifiReach = [Reachability reachabilityForLocalWiFi];
    [self.wifiReach startNotifier];
}

//Called by Reachability whenever status changes.
- (void)reachabilityChanged:(NSNotification* )note {
    Reachability *curReach = (Reachability *)[note object];
    NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
    NSLog(@"Reachability changed: %@", curReach);
    networkStatus = [curReach currentReachabilityStatus];
    

    // Try
    if ([self isParseReachable] && [PFUser currentUser] ) {
        // Parse is reachable and calling this method will only upload a vybe if there is
        [[VYBMyVybeStore sharedStore] uploadDelayedVybes];
    }
}

@end
