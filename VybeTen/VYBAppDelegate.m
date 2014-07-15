//
//  VYBAppDelegate.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 19..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

/* Release
#define PARSE_APPLICATION_ID        @"m5Im7uDcY5rieEbPyzRfV2Dq6YegS3kAQwxiDMFZ"
#define PARSE_CLIENT_KEY            @"WLqeqlf4qVVk5jF6yHSWGxw3UzUQwUtmAk9vCPfB"
*/

/* Debug */
#define PARSE_APPLICATION_ID        @"gYVd0gSQavfnxcvIyFhns8j0KKyp0XHekKdrjJkC"
#define PARSE_CLIENT_KEY            @"6y6eMRZq5GAa5ihS2GSjFB0xwmnuatvuJBhYQ1Af"


#import <AVFoundation/AVFoundation.h>
#import <HockeySDK/HockeySDK.h>
#import "VYBAppDelegate.h"
#import "VYBCaptureViewController.h"
#import "VYBPlayerViewController.h"
#import "VYBMyVybeStore.h"
#import "VYBCache.h"
#import "VYBUtility.h"
#import "Reachability.h"

@interface VYBAppDelegate ()

@property (nonatomic, strong) Reachability *hostReach;
@property (nonatomic, strong) Reachability *internetReach;
@property (nonatomic, strong) Reachability *wifiReach;
@property (nonatomic, strong) NSString *uniqueID;

@end

@implementation VYBAppDelegate {
    VYBCaptureViewController *captureVC;
    VYBPlayerViewController *playerVC;
}

@synthesize networkStatus;
@synthesize hostReach;
@synthesize internetReach;
@synthesize wifiReach;


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

    [Parse setApplicationId:PARSE_APPLICATION_ID
                  clientKey:PARSE_CLIENT_KEY];
    NSLog(@"parse app id: %@", PARSE_APPLICATION_ID);
    
    // Parse Analaytics
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    // Push Notification Initialization
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
     UIRemoteNotificationTypeAlert|
     UIRemoteNotificationTypeSound];
    
    self.uniqueID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
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
    
    captureVC = [[VYBCaptureViewController alloc] init];    
    
    self.navigationVC = [[VYBNavigationController alloc] initWithRootViewController:captureVC];
    self.navigationVC.navigationBarHidden = YES;
    
    if (![PFUser currentUser]) {
        //log in
        [PFUser logInWithUsernameInBackground:self.uniqueID password:self.uniqueID block:^(PFUser *user, NSError *error) {
            if (!error) {
                if ([PFUser currentUser]) {
                    // start vybing
                    //[self.navigationVC pushViewController:captureVC animated:NO];
                }
            } else {
                // sign up
                PFUser *newUser = [PFUser user];
                newUser.username = self.uniqueID;
                newUser.password = self.uniqueID;
                [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (!error) {
                        if ([PFUser currentUser]) {
                            // start vybibng
                            //[self.navigationVC pushViewController:captureVC animated:NO];
                        }
                    } else {
                        NSLog(@"sign up failed: %@", error);
                    }
                }];
            }
        }];
    } else {
        //[self.navigationVC pushViewController:captureVC animated:NO];
    }
    
    [self.window setRootViewController:self.navigationVC];
    
    self.window.backgroundColor = [UIColor blackColor];
    [self.window makeKeyAndVisible];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    
    return YES;
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
    
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveEventually];
    }
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];

}

#pragma mark - AppDelegate

- (BOOL)isParseReachable {
    return self.networkStatus != NotReachable;
}

#pragma mark - UIPageViewControllerDataSource 

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(id)viewController {
    NSInteger idx = [viewController pageIndex] + 1;
    if (idx < self.viewControllers.count) {
        return self.viewControllers[idx];
    }
    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(id)viewController {
    NSInteger idx = [viewController pageIndex] - 1;
    if (idx < 0) {
        return nil;
    }
    return self.viewControllers[idx];
}

- (void)swipeToCaptureScreen {
    [self.pageVC setViewControllers:@[self.viewControllers[0]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
}

- (void)swipeToPlayerScreen {
    [self.pageVC setViewControllers:@[self.viewControllers[1]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
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
