//
//  VYBAppDelegate.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 19..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <HockeySDK/HockeySDK.h>
#import "VYBAppDelegate.h"
#import "VYBNavigationController.h"
#import "VYBHomeViewController.h"
#import "VYBTribesViewController.h"
#import "VYBFriendsViewController.h"
#import "VYBPlayerViewController.h"
#import "VYBMyVybeStore.h"
#import "VYBCache.h"
#import "VYBUtility.h"
#import "Reachability.h"

@interface VYBAppDelegate ()

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
@synthesize viewControllers;


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
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveEventually];
    }
    
    // Access Control
    PFACL *defaultACL = [PFACL ACL];
    // Enable public read access by default, with any newly created PFObjects belonging to the current user
    [defaultACL setPublicReadAccess:YES];
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
        
    pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    pageController.dataSource = self;

    // page0 is TRIBES
    VYBTribesViewController *tribesVC = [[VYBTribesViewController alloc] init];
    VYBNavigationController *tribeNavigation = [VYBNavigationController navigationControllerForPageIndex:VYBTribesPageIndex withRootViewController:tribesVC];
    // page1 is HOME and it's the Starting Page
    VYBHomeViewController *homeVC = [[VYBHomeViewController alloc] init];
    VYBNavigationController *homeNavigation = [VYBNavigationController navigationControllerForPageIndex:VYBHomePageIndex withRootViewController:homeVC];
    // page2 is FRIENDS
    VYBFriendsViewController *friendsVC = [[VYBFriendsViewController alloc] init];
    VYBNavigationController *friendsNavigation = [VYBNavigationController navigationControllerForPageIndex:VYBFriendsPageIndex withRootViewController:friendsVC];
    
    viewControllers = [NSArray arrayWithObjects:tribeNavigation, homeNavigation, friendsNavigation, nil];
    [pageController setViewControllers:@[homeNavigation] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [self.window setRootViewController:pageController];
    
    if ([PFUser currentUser]) {
        [homeVC refreshUserData];
    }
    
    self.window.backgroundColor = [UIColor blackColor];
    [self.window makeKeyAndVisible];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    // If the app was launched from tapping on a push notification
    NSDictionary *remoteNotificationPayload = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotificationPayload) {
        [self handlePush:remoteNotificationPayload];
    }
    
    return YES;
}


#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(id)viewController {
    NSInteger idx = [viewController pageIndex] - 1;
    if (idx < 0) {
        return nil;
    }
    return [viewControllers objectAtIndex:idx];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(id)viewController {
    NSInteger idx = [viewController pageIndex] + 1;
    if (idx >= viewControllers.count) {
        return nil;
    }
    return [viewControllers objectAtIndex:idx];
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



/**
 * PFPush Settigs 
 **/

- (void)handlePush:(NSDictionary *)remoteNotificationPayload {
    [[NSNotificationCenter defaultCenter] postNotificationName:VYBAppDelegateApplicationDidReceiveRemoteNotification object:nil userInfo:remoteNotificationPayload];
    
    if (![PFUser currentUser]) {
        return;
    }
    
    // Following Activity
    NSString *fromUserObjId = [remoteNotificationPayload objectForKey:kVYBPushPayloadActivityFromUserObjectIdKey];
    if (fromUserObjId && fromUserObjId.length > 0) {
        PFQuery *query = [PFUser query];
        query.cachePolicy = kPFCachePolicyCacheElseNetwork;
        [query getObjectInBackgroundWithId:fromUserObjId block:^(PFObject *object, NSError *error) {
            if (!error) {
                VYBNavigationController *friendsVC = self.viewControllers[VYBFriendsPageIndex];
                [self.pageController setViewControllers:@[friendsVC] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
            }
        }];
        return;
    }
    
    // New vybe, so start playing that vybe right away
    NSString *vybeObjectId = [remoteNotificationPayload objectForKeyedSubscript:kVYBPushPayloadVybeObjectIdKey];
    if (vybeObjectId && vybeObjectId.length > 0) {
        PFQuery *query = [PFQuery queryWithClassName:kVYBVybeClassKey];
        query.cachePolicy = kPFCachePolicyCacheElseNetwork;
        [query getObjectInBackgroundWithId:vybeObjectId block:^(PFObject *object, NSError *error) {
            if (!error) {
                VYBNavigationController *homeNavigation = self.viewControllers[VYBHomePageIndex];
                [self.pageController setViewControllers:@[homeNavigation] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
                if (homeNavigation.presentedViewController) {
                    [homeNavigation dismissViewControllerAnimated:NO completion:^{
                        VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
                        [homeNavigation presentViewController:playerVC animated:NO completion:^{
                            [playerVC playVybe:object];
                        }];
                    }];
                } else {
                    VYBPlayerViewController *playerVC = [[VYBPlayerViewController alloc] init];
                    [homeNavigation presentViewController:playerVC animated:NO completion:^{
                        [playerVC playVybe:object];
                    }];
                }
            }
        }];
        return;
    }
    
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
    }
    
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveEventually];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	if (error.code != 3010) { // 3010 is for the iPhone Simulator
        NSLog(@"Application failed to register for push notifications: %@", error);
	}
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[NSNotificationCenter defaultCenter] postNotificationName:VYBAppDelegateApplicationDidReceiveRemoteNotification object:nil userInfo:userInfo];
    
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        // Tracks app open due to a push notification when the app was not active
    }
    
    if (userInfo) {
        [self handlePush:userInfo];
    }
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
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveEventually];
    }
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
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
    //NSLog(@"Reachability changed: %@", curReach);
    networkStatus = [curReach currentReachabilityStatus];
    

    // Try
    if ([self isParseReachable] && [PFUser currentUser] ) {
        // Parse is reachable and calling this method will only upload a vybe if there is
        [[VYBMyVybeStore sharedStore] uploadDelayedVybes];
    }
}

@end
