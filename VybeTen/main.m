//
//  main.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 19..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "VYBAppDelegate.h"

int main(int argc, char * argv[])
{
    @autoreleasepool {
        // In order to fix language of placemark attributes (e.g. city name)
        [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithObject:@"en"] forKey:@"AppleLanguages"];
        
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([VYBAppDelegate class]));
    }
}
