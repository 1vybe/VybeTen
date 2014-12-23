//
//  VYBAppDelegate.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 19..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//


#import <AVFoundation/AVFoundation.h>
#import <GAI.h>
#import <GAIDictionaryBuilder.h>
#import <GAITracker.h>
#import <GAIFields.h>
//NOTE: Take out this part when releasing to TESTFLIGHT
//#import <HockeySDK/HockeySDK.h>
#import <ParseCrashReporting/ParseCrashReporting.h>
#import "VYBAppDelegate.h"
#import "VYBCaptureViewController.h"
#import "VYBPlayerViewController.h"
#import "VYBPermissionViewController.h"
#import "VYBActivityTableViewController.h"
#import "VYBWelcomeViewController.h"
#import "VYBMyVybeStore.h"
#import "VYBCache.h"
#import "VYBUtility.h"
#import "Reachability.h"

#import "VybeTen-Swift.h"

@interface VYBAppDelegate ()

@property (nonatomic, strong) Reachability *hostReach;
@property (nonatomic, strong) Reachability *internetReach;
@property (nonatomic, strong) Reachability *wifiReach;
@property (nonatomic, strong) NSString *uniqueID;

@property (nonatomic) VYBNavigationController *mainNavController;
@property (nonatomic, strong) SwipeContainerController *swipeContainerController;
@property (nonatomic) VYBPermissionViewController *permissionController;
@property (nonatomic, strong) VYBWelcomeViewController *welcomeViewController;

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
  
  //NOTE: Take out this part when releasing to TESTFLIGHT
  /* HockeyApp Initilization */
//  BITHockeyManager *hockeyManager = [BITHockeyManager sharedHockeyManager];
//  [hockeyManager configureWithIdentifier:HOCKEY_APP_ID];
//  hockeyManager.updateManager.checkForUpdateOnLaunch = YES;
//  hockeyManager.updateManager.updateSetting = BITUpdateCheckStartup;
//  [hockeyManager startManager];
//  [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
  
  //NOTE: Change this part when releasing to TESTFLIGHT
  // Parse Initialization
  [ParseCrashReporting enable];
  [Parse setApplicationId:PARSE_APPLICATION_ID_DEV
                clientKey:PARSE_CLIENT_KEY_DEV];

  BOOL preBackgroundPush = ![application respondsToSelector:@selector(backgroundRefreshStatus)];
  BOOL oldPushHandlerOnly = ![self respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)];
  BOOL noPushPayload = ![launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
  if (preBackgroundPush || oldPushHandlerOnly || noPushPayload) {
// We want to exclude debugging from analytics.
#ifdef DEBUG
#else
    if (![[ConfigManager sharedInstance] currentUserExcludedFromAnalytics]) {
      [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    }
#endif
  }
  
  // Register defaults for NSUserDefaults
  NSURL *prefsFileURL = [[NSBundle mainBundle] URLForResource:@"DefaultPreferences" withExtension:@"plist"];
  NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfURL:prefsFileURL];
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
  
  // Register for remote notification
  [self checkNotificationPermissionAndRegister:application];

#ifdef DEBUG
  // We want to exclude debugging from analytics.
#else
  // Optional: automatically send uncaught exceptions to Google Analytics.
  [GAI sharedInstance].trackUncaughtExceptions = YES;
  // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
  [GAI sharedInstance].dispatchInterval = 20;
  // Optional: set Logger to VERBOSE for debug information.
  [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelNone];
  // Initialize tracker. Replace with your tracking ID.
  id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:GA_TRACKING_ID];
  [tracker send:[[[GAIDictionaryBuilder createEventWithCategory:@"UX"
                                                         action:@"App Start"
                                                          label:nil
                                                          value:nil] set:@"start" forKey:kGAISessionControl] build]];
#endif

  // Clearing Push-noti Badge number
  PFInstallation *currentInstallation = [PFInstallation currentInstallation];
  if (currentInstallation.badge != 0) {
    currentInstallation.badge = 0;
    //[currentInstallation saveEventually];
  }

  // Access Control
  PFACL *defaultACL = [PFACL ACL];
  // Enable public read access by default, with any newly created PFObjects belonging to the current user
  [defaultACL setPublicReadAccess:YES];
  [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
  
  self.welcomeViewController = [[VYBWelcomeViewController alloc] init];
  
  self.mainNavController = [[VYBNavigationController alloc] initWithRootViewController:self.welcomeViewController];
  self.mainNavController.navigationBarHidden = YES;
  
  [self.window setRootViewController:self.mainNavController];
  
  self.window.backgroundColor = [UIColor blackColor];
  [self.window makeKeyAndVisible];
  
  // Handle push if the app is launched from notification
  [self handlePush:launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]];
  
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  [[NSNotificationCenter defaultCenter] postNotificationName:VYBAppDelegateApplicationDidEnterBackgourndNotification object:nil];
}


- (void)applicationWillTerminate:(UIApplication *)application
{
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  [[UIApplication sharedApplication] cancelAllLocalNotifications];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:VYBAppDelegateApplicationDidBecomeActiveNotification object:self];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  [self.swipeContainerController moveToCaptureScreen];

  [[ConfigManager sharedInstance] fetchIfNeeded];
}

#pragma mark - Notification

- (void)checkNotificationPermissionAndRegister:(UIApplication *)application {
  // iOS8
  if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
    NSString *notiPermission = [[NSUserDefaults standardUserDefaults] objectForKey:kVYBUserDefaultsNotificationPermissionKey];
    
    if ( [notiPermission isEqualToString:kVYBUserDefaultsNotificationPermissionGrantedKey] ) {
      [application registerForRemoteNotifications];
    }
    // Else Do nothing because request should be made from Activity screen
  }
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
  if (notificationSettings.types == UIUserNotificationTypeNone) {
    // Permission denied
    [[NSUserDefaults standardUserDefaults] setObject:kVYBUserDefaultsNotificationPermissionDeniedKey forKey:kVYBUserDefaultsNotificationPermissionKey];
  }
  else {
    // Permission granted
    [[NSUserDefaults standardUserDefaults] setObject:kVYBUserDefaultsNotificationPermissionGrantedKey forKey:kVYBUserDefaultsNotificationPermissionKey];
  }
  
  [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  PFInstallation *currentInstallation = [PFInstallation currentInstallation];
  
  [currentInstallation setDeviceTokenFromData:deviceToken];
  [currentInstallation saveEventually];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  if (error.code != 3010) { // 3010 is for the iPhone Simulator
  }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
  [[NSNotificationCenter defaultCenter] postNotificationName:VYBAppDelegateApplicationDidReceiveRemoteNotification object:userInfo];
  
  if ([UIApplication sharedApplication].applicationState == UIApplicationStateInactive) {
#ifdef DEBUG
#else
    // Tracks app open due to a push notification when the app was not active
    if (![[ConfigManager sharedInstance] currentUserExcludedFromAnalytics]) {
      [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
#endif
  }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  
  [[NSNotificationCenter defaultCenter] postNotificationName:VYBAppDelegateApplicationDidReceiveRemoteNotification object:userInfo];
  
  if ([UIApplication sharedApplication].applicationState == UIApplicationStateInactive) {
#ifdef DEBUG
#else
    if (![[ConfigManager sharedInstance] currentUserExcludedFromAnalytics]) {
      [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
#endif
    [self.swipeContainerController moveToActivityScreen];
  }
  
  if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
    application.applicationIconBadgeNumber = application.applicationIconBadgeNumber + 1;
  }
  
  completionHandler(UIBackgroundFetchResultNoData);
}


- (void)handlePush:(NSDictionary *)payload {
  
}

#pragma mark - AppDelegate

- (BOOL)isParseReachable {
  return self.networkStatus != NotReachable;
}

- (void)presentFirstPageViewControllerAnimated:(BOOL)animated {
  //    VYBLogInViewController *logInViewController = [[VYBLogInViewController alloc] init];
  LogInViewController *logInViewController = [[LogInViewController alloc] init];
  logInViewController.fields = PFLogInFieldsDefault;
  logInViewController.delegate = self;
  
  SignUpViewController *signUpController = [[SignUpViewController alloc] init];
  signUpController.fields = PFSignUpFieldsDefault;
  signUpController.delegate = logInViewController;
  
  logInViewController.signUpController = signUpController;
  [self.mainNavController pushViewController:logInViewController animated:animated];
}

#pragma mark -
#pragma mark PFLogInViewControllerDelegate

- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
#ifdef DEBUG
#else
  if (![[ConfigManager sharedInstance] currentUserExcludedFromAnalytics]) {
    [PFAnalytics trackAppOpenedWithLaunchOptions:nil];
  }
#endif
  [self proceedToMainInterface];
}

#pragma mark -

- (void)presentFirstPage {
  [self presentFirstPageViewControllerAnimated:YES];
}

- (void)proceedToMainInterface {
  [self.mainNavController popToRootViewControllerAnimated:NO];

  [self setUpViewControllers];
}

- (void)setUpViewControllers {
  VYBActivityTableViewController *activityVC = [[UIStoryboard storyboardWithName:@"Activity" bundle:nil] instantiateInitialViewController];
  VYBNavigationController *activityNav = [[VYBNavigationController alloc] initWithRootViewController:activityVC];
  VYBCaptureViewController *captureVC = [[VYBCaptureViewController alloc] initWithNibName:@"VYBCaptureViewController" bundle:nil];
  
  self.swipeContainerController = [[SwipeContainerController alloc] initWithViewControllers:@[captureVC, activityNav]];
  
  [self.mainNavController pushViewController:self.swipeContainerController animated:NO];
  
  // Checking permissions
  self.permissionController = [[VYBPermissionViewController alloc] init];
  BOOL granted = [self.permissionController checkPermissionSettings];
  if (!granted)
    [self.mainNavController pushViewController:self.permissionController animated:NO];
  
  UserPromptsViewController *userPrompts = [[UIStoryboard storyboardWithName:@"UserPrompts" bundle:nil] instantiateInitialViewController];
  BOOL userPromptsSeen = [[[NSUserDefaults standardUserDefaults] objectForKey:kVYBUserDefaultsUserPromptsSeenKey] boolValue];
  if (!userPromptsSeen) {
    [self.mainNavController pushViewController:userPrompts animated:NO];
  }
  UserAgreementViewController *userAgreementVC = [[UserAgreementViewController alloc] initWithNibName:@"UserAgreementViewController" bundle:nil];
  BOOL termsAgreed = [[[PFUser currentUser] objectForKey:kVYBUserTermsAgreedKey] boolValue];
  if (!termsAgreed) {
    [self.mainNavController pushViewController:userAgreementVC animated:NO];
  }
  
  // Regular clean-up tmp directory
  [VYBUtility clearTempDirectory];
}

- (void)logOut {
  // clear cache
  [[VYBCache sharedCache] clear];
  
  //    // clear NSUserDefaults
  //    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPAPUserDefaultsCacheFacebookFriendsKey];
  //    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kVYBUserDefaultsActivityFeedViewControllerLastRefreshKey];
  //    [[NSUserDefaults standardUserDefaults] synchronize];
  
  // Unsubscribe from push notifications by removing the user association from the current installation.
  [[PFInstallation currentInstallation] removeObjectForKey:kVYBInstallationUserKey];
  [[PFInstallation currentInstallation] saveInBackground];
  
  // Clear all caches
  [PFQuery clearAllCachedResults];
  
  // Log out
  [PFUser logOut];
  
  // clear out cached data, view controllers, etc
  [self.mainNavController popToRootViewControllerAnimated:NO];
  
  
  self.viewControllers = nil;
  self.permissionController = nil;
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
}


@end
