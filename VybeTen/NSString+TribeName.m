//
//  NSString+TribeName.m
//  Vybe
//
//  Created by Jinsu Kim on 2/16/15.
//  Copyright (c) 2015 Vybe. All rights reserved.
//

#import "NSString+TribeName.h"

@implementation NSString (TribeName)

- (BOOL)isValidTribeName {
  NSString *nameRegex = @"[a-zA-Z0-9_]+";
  NSPredicate *nameTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", nameRegex];
  BOOL isValid = [nameTest evaluateWithObject:self];
  return isValid;
}

@end
