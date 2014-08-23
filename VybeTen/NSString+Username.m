//
//  NSString+Username.m
//  VybeTen
//
//  Created by Mohammed Tangestani on 2014-08-22.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "NSString+Username.h"

@implementation NSString (Username)

- (BOOL)isValidUsername {
    NSString *usernameRegex = @"[a-zA-Z0-9_]+";
    NSPredicate *usernameTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", usernameRegex];
    BOOL isValid = [usernameTest evaluateWithObject:self];
    return isValid;
}

@end
