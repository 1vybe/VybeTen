//
//  NSString+Email.m
//  VybeTen
//
//  Created by Mohammed Tangestani on 2014-08-22.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "NSString+Email.h"

@implementation NSString (Email)

- (BOOL)isValidEmail {
    NSString *emailRegex = @"[a-zA-Z0-9_.+-]+@[a-zA-Z0-9_.+-]+\\.[a-zA-Z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    BOOL isValid = [emailTest evaluateWithObject:self];
    return isValid;
}

@end
