//
//  VYBMyTribeStore.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 8..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSS3/AWSS3.h>

@interface VYBMyTribeStore : NSObject <AmazonServiceRequestDelegate> {
    NSMutableArray *myTribeVybes;
}
@property (nonatomic) AmazonS3Client *s3;
+ (VYBMyTribeStore *)sharedStore;
- (NSArray *)myTribeVybes;
- (void)syncMyTribeWithCloud;
@end
