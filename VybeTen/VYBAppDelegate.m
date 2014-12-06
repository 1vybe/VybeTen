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
#import <HockeySDK/HockeySDK.h>
#import "VYBAppDelegate.h"
#import "VYBUserStore.h"
#import "VYBCaptureViewController.h"
#import "VYBPlayerViewController.h"
#import "VYBPermissionViewController.h"
#import "VYBActivityTableViewController.h"
#import "VYBWelcomeViewController.h"
#import "VYBMyVybeStore.h"
#import "VYBCache.h"
#import "VYBUtility.h"
#import "Reachability.h"

@interface VYBAppDelegate ()

@property (nonatomic, strong) Reachability *hostReach;
@property (nonatomic, strong) Reachability *internetReach;
@property (nonatomic, strong) Reachability *wifiReach;
@property (nonatomic, strong) NSString *uniqueID;

@property (nonatomic) VYBNavigationController *mainNavController;
@property (nonatomic, strong) SwipeContainerController *swipeContainerController;
@property (nonatomic) VYBPermissionViewController *permissionController;
//@property (nonatomic, strong) VYBActivityTableViewController *activityVC;
@property (nonatomic, strong) VYBWelcomeViewController *welcomeViewController;

- (void)setupAppearance;
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
  
  /* HockeyApp Initilization */
  BITHockeyManager *hockeyManager = [BITHockeyManager sharedHockeyManager];
  [hockeyManager configureWithIdentifier:HOCKEY_APP_ID];
  hockeyManager.updateManager.checkForUpdateOnLaunch = YES;
  hockeyManager.updateManager.updateSetting = BITUpdateCheckStartup;
  [hockeyManager startManager];
  
  [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
  
  
  // Parse Initialization
  [Parse setApplicationId:PARSE_APPLICATION_ID
                clientKey:PARSE_CLIENT_KEY];
  
  BOOL preBackgroundPush = ![application respondsToSelector:@selector(backgroundRefreshStatus)];
  BOOL oldPushHandlerOnly = ![self respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)];
  BOOL noPushPayload = ![launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
  if (preBackgroundPush || oldPushHandlerOnly || noPushPayload) {
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
  }
  
  
  // Register defaults for NSUserDefaults
  NSURL *prefsFileURL = [[NSBundle mainBundle] URLForResource:@"DefaultPreferences" withExtension:@"plist"];
  NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfURL:prefsFileURL];
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
  
  // Register for remote notification
  [self checkNotificationPermissionAndRegister:application];
  
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
  
  // Clearing Push-noti Badge number
  /*
   PFInstallation *currentInstallation = [PFInstallation currentInstallation];
   
   if (currentInstallation.badge != 0) {
   currentInstallation.badge = 0;
   [currentInstallation saveEventually];
   }
   */
  
  // Access Control
  PFACL *defaultACL = [PFACL ACL];
  // Enable public read access by default, with any newly created PFObjects belonging to the current user
  [defaultACL setPublicReadAccess:YES];
  [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
  
  /* navigation bar settings */
  [self setupAppearance];
  
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

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(id)viewController {
  NSInteger nextPageIndex = [viewController pageIndex] + 1;
  if (nextPageIndex == self.viewControllers.count)
    return nil;
  
  return self.viewControllers[nextPageIndex];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(id)viewController {
  NSInteger prevPageIndex = [viewController pageIndex] - 1;
  if (prevPageIndex < 0)
    return nil;
  
  return self.viewControllers[prevPageIndex];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  [[NSNotificationCenter defaultCenter] postNotificationName:VYBAppDelegateApplicationDidEnterBackgourndNotification object:nil];
  
  BOOL success = [[VYBMyVybeStore sharedStore] saveChanges];
  
  success = [[VYBUserStore sharedStore] saveChanges];
  
}


- (void)applicationWillTerminate:(UIApplication *)application
{
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  BOOL success = [[VYBMyVybeStore sharedStore] saveChanges];
  
  success = [[VYBUserStore sharedStore] saveChanges];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  [[UIApplication sharedApplication] cancelAllLocalNotifications];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:VYBAppDelegateApplicationDidBecomeActiveNotification object:self];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  [self.swipeContainerController moveToCaptureScreen];
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
    // Tracks app open due to a push notification when the app was not active
    [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
  }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  
  [[NSNotificationCenter defaultCenter] postNotificationName:VYBAppDelegateApplicationDidReceiveRemoteNotification object:userInfo];
  
  if ([UIApplication sharedApplication].applicationState == UIApplicationStateInactive) {
    [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
  }
  
  if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
    application.applicationIconBadgeNumber = application.applicationIconBadgeNumber + 1;
  }
  
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
  
  UserAgreementViewController *userAgreementVC = [[UserAgreementViewController alloc] initWithNibName:@"UserAgreementViewController" bundle:nil];
  BOOL termsAgreed = [[[PFUser currentUser] objectForKey:kVYBUserTermsAgreedKey] boolValue];
  if (!termsAgreed) {
    [self.mainNavController pushViewController:userAgreementVC animated:NO];
  }
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

- (void)setupAppearance {
  [[UINavigationBar appearance] setTintColor:COLOR_MAIN];
  // title font
  NSMutableDictionary *titleBarAttributes = [NSMutableDictionary dictionaryWithDictionary: [[UINavigationBar appearance] titleTextAttributes]];
  [titleBarAttributes setValue:[UIFont fontWithName:@"ProximaNovaSoft-Regular" size:20.0] forKey:NSFontAttributeName];
  [titleBarAttributes setValue:COLOR_MAIN forKey:NSForegroundColorAttributeName];
  [[UINavigationBar appearance] setTitleTextAttributes:titleBarAttributes];
  
  // back button image
  //    [[UINavigationBar appearance] setBackIndicatorImage:[UIImage imageNamed:@"button_navi_back.png"]];
  //    [[UINavigationBar appearance] setBackIndicatorTransitionMaskImage:[UIImage imageNamed:@"button_navi_back.png"]];
}

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
