//
//  VYBAppDelegate.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 19..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#define PARSE_APPLICATION_ID        @"m5Im7uDcY5rieEbPyzRfV2Dq6YegS3kAQwxiDMFZ"
#define PARSE_CLIENT_KEY            @"WLqeqlf4qVVk5jF6yHSWGxw3UzUQwUtmAk9vCPfB"

/* House
#define PARSE_APPLICATION_ID        @"gYVd0gSQavfnxcvIyFhns8j0KKyp0XHekKdrjJkC"
#define PARSE_CLIENT_KEY            @"6y6eMRZq5GAa5ihS2GSjFB0xwmnuatvuJBhYQ1Af"
*/

#import <AVFoundation/AVFoundation.h>
#import <GAI.h>
#import <GAIDictionaryBuilder.h>
#import <GAITracker.h>
#import <GAIFields.h>
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


@property (nonatomic, strong) VYBCaptureViewController *captureVC;
@property (nonatomic, strong) VYBPlayerViewController *playerVC;

@end

@implementation VYBAppDelegate

@synthesize networkStatus;
@synthesize hostReach;
@synthesize internetReach;
@synthesize wifiReach;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Use Reachability to monitor connectivity
    [self monitorReachability];
    
    // Parse Initialization
    [Parse setApplicationId:PARSE_APPLICATION_ID
                  clientKey:PARSE_CLIENT_KEY];
    
    // Parse Analaytics
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    // Push Notification Initialization
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
     UIRemoteNotificationTypeAlert|
     UIRemoteNotificationTypeSound];
    
    // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    
    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].dispatchInterval = 20;
    
    // Optional: set Logger to VERBOSE for debug information.
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelNone];
    
    // Initialize tracker. Replace with your tracking ID.
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:GA_TRACKING_ID];
    [tracker send:[[[GAIDictionaryBuilder createEventWithCategory:@"UX"
                                                           action:@"appstart"
                                                            label:nil
                                                            value:nil] set:@"start" forKey:kGAISessionControl] build]];

    
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
    
    self.captureVC = [[VYBCaptureViewController alloc] init];
    
    self.navigationVC = [[VYBNavigationController alloc] initWithRootViewController:self.captureVC];
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
