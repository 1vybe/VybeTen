//
//  VYBAppDelegate.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 19..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "VYBAppDelegate.h"
#import "VYBMenuViewController.h"
#import "VYBCaptureViewController.h"
#import "VYBVybeStore.h"

@implementation VYBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    VYBCaptureViewController *captureVC = [[VYBCaptureViewController alloc] init];
    VYBMenuViewController *menuVC = [[VYBMenuViewController alloc] init];
    
    UINavigationController *navContoller = [[UINavigationController alloc] initWithRootViewController:captureVC];
    [navContoller pushViewController:menuVC animated:NO];

    // Set navigation controller's background as preview layer from video input
    AVCaptureDevice *device = [[AVCaptureDevice alloc] init];
    
    [self.window setRootViewController:navContoller];
    
    self.window.backgroundColor = [UIColor whiteColor];
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
    
    BOOL success = [[VYBVybeStore sharedStore] saveChanges];
    if (success)
        NSLog(@"My vybes are saved. :)");
    else
        NSLog(@"My vybes will be lost. :(");
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
