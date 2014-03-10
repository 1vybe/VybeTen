//
//  VYBMyVybeStore.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 24..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSS3/AWSS3.h>
#import "VYBVybe.h"

@interface VYBMyVybeStore : NSObject <AmazonServiceRequestDelegate> {
    NSMutableArray *myVybes;
}
@property (nonatomic) AmazonS3Client *s3;

+ (VYBMyVybeStore *)sharedStore;
- (NSArray *)myVybes;
- (void)listVybes;
- (void)addVybe:(VYBVybe *)v;
- (void)removeVybe:(VYBVybe *)v;
- (NSString *)myVybesArchivePath;
- (BOOL)saveChanges;

@end
