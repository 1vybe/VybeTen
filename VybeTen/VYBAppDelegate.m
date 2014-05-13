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
#import "VYBMyVybeStore.h"
#import "VYBMyTribeStore.h"
#import "VYBConstants.h"
#import <HockeySDK/HockeySDK.h>

@implementation VYBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

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
    [defaultACL setPublicReadAccess:YES];
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];

    
    /**
     * Set navigation controller's background as preview layer from video input
     */
    self.navController = [[UINavigationController alloc] init];
    [[self.navController navigationBar] setHidden:YES];

    // Setup for video capturing session
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    [session setSessionPreset:AVCaptureSessionPresetMedium];
    // Add video input from camera
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
    if ( [session canAddInput:videoInput] )
        [session addInput:videoInput];
    // Setup preview layer
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [[previewLayer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    // Display preview layer
    CALayer *rootLayer = [[self.navController view] layer];
    [rootLayer setMasksToBounds:YES];
    [previewLayer setFrame:CGRectMake(0, 0, rootLayer.bounds.size.height, rootLayer.bounds.size.width)]; // width and height are switched in landscape mode
    [rootLayer insertSublayer:previewLayer atIndex:0];
    // Add audio input from mic
    AVCaptureDevice *inputDeviceAudio = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *deviceAudioInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDeviceAudio error:nil];
    if ( [session canAddInput:deviceAudioInput] )
        [session addInput:deviceAudioInput];
    // Add movie file output
    /* Orientation must be set AFTER FileOutput is added to session */
    AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    Float64 totalSeconds = 7;
    int32_t preferredTimeScale = 30;
    CMTime maxDuration = CMTimeMakeWithSeconds(totalSeconds, preferredTimeScale);
    movieFileOutput.maxRecordedDuration = maxDuration;
    movieFileOutput.minFreeDiskSpaceLimit = 1024 * 512;
    if ( [session canAddOutput:movieFileOutput] )
        [session addOutput:movieFileOutput];
    AVCaptureConnection *movieConnection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    [movieConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    
    
    VYBCaptureViewController *captureVC = [[VYBCaptureViewController alloc] init];
    [captureVC setSession:session withVideoInput:videoInput withMovieFileOutput:movieFileOutput];
    [session startRunning];
    
    self.welcomeViewController = [[VYBWelcomeViewController alloc] init];

    self.navController.modalPresentationStyle = UIModalPresentationCurrentContext;
    
    [self.window setRootViewController:self.navController];
    [self.navController pushViewController:captureVC animated:NO];
    [self.navController pushViewController:self.welcomeViewController animated:NO];

    self.window.backgroundColor = [UIColor blackColor];
    [self.window makeKeyAndVisible];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
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
    
    success = [[VYBMyTribeStore sharedStore] saveChanges];
    if (success)
        NSLog(@"My tribes are saved. :)");
    else
        NSLog(@"My tribes will be lost. :(");
    //[[VYBMyTribeStore sharedStore] listVybes];
    
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
    
    //success = [[VYBMyTribeStore sharedStore] clear];
    //NSLog(@"My tribes caches are cleared. :)");
    //NSLog(@"My tribes caches are not cleared. :(");
    //[[VYBMyTribeStore sharedStore] listVybes];
}

- (void)presentLoginViewController {
    [self presentLoginViewControllerAnimated:YES];
}

- (void)presentLoginViewControllerAnimated:(BOOL)animated {
    VYBLoginViewController *logInViewController = [[VYBLoginViewController alloc] init];
    [logInViewController setDelegate:self];
    [logInViewController setFields:PFLogInFieldsFacebook | PFLogInFieldsTwitter];
    NSArray *permissionsArray = @[ @"user_friends", @"public_profile" ];
    [logInViewController setFacebookPermissions:permissionsArray];
    
    [self.welcomeViewController presentViewController:logInViewController animated:NO completion:nil];
}

- (void)logOut {
    /* TODO */
    /*
     
    // clear cache
    [[PAPCache sharedCache] clear];

    // clear NSUserDefaults
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPAPUserDefaultsCacheFacebookFriendsKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPAPUserDefaultsActivityFeedViewControllerLastRefreshKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // Unsubscribe from push notifications by removing the user association from the current installation.
    [[PFInstallation currentInstallation] removeObjectForKey:kPAPInstallationUserKey];
    [[PFInstallation currentInstallation] saveInBackground];
    
    // Clear all caches
    [PFQuery clearAllCachedResults];
     
    */
    
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
    [self.navController dismissViewControllerAnimated:NO completion:nil];
}

- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
    NSLog(@"Failed to log in...");
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
    
    [PFPush handlePush:userInfo];
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
    /* TODO: Update Badge Number */
    
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
}

/**
 * Facebook Request methods (Friends Update)
 **/

- (void)facebookRequestDidLoad:(id)result {
    PFUser *user = [PFUser currentUser];
    
    NSArray *data = [result objectForKey:@"data"];
    
    if (data) {
        NSMutableArray *facebookIDs = [[NSMutableArray alloc] initWithCapacity:[data count]];
        for (NSDictionary *friendData in data) {
            if (friendData[@"id"]) {
                [facebookIDs addObject:friendData[@"id"]];
            }
        }
        
        if (user) {
            if ([user objectForKey:kVYBUserFacebookFriendsKey]) {
                [user removeObjectForKey:kVYBUserFacebookFriendsKey];
            }
            // First time user's friends list is updated
            /* TODO: Don't auto-send a friend request */
            if (![user objectForKey:kVYBUserAlreadyAutoFollowedFacebookFriendsKey]) {
                [user setObject:@YES forKey:kVYBUserAlreadyAutoFollowedFacebookFriendsKey];
                
                NSError *error = nil;
                
                //Facebook friends list
                PFQuery *facebookFriendsQuery = [PFUser query];
                [facebookFriendsQuery whereKey:kVYBUserFacebookIDKey containedIn:facebookIDs];
                
                NSArray *vybeFriends = [facebookFriendsQuery findObjects:&error];
                
                if (!error) {
                    [vybeFriends enumerateObjectsUsingBlock:^(PFUser *newFriend, NSUInteger idx, BOOL *stop) {
                        /* TODO: Activity */
                        
                        
                    }];
                }
            }
            [user saveEventually];
        } else {
            NSLog(@"No user info is found. Forcing logging out");
            [self logOut];
        }
    }
    else {
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

@end
