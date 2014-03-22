//
//  VYBMyTribeStore.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 8..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSS3/AWSS3.h>
#import "VYBVybe.h"

@interface VYBMyTribeStore : NSObject <AmazonServiceRequestDelegate> {
    NSMutableDictionary *myTribesVybes;
    NSString *adId;
}
@property (nonatomic) AmazonS3Client *s3;

+ (VYBMyTribeStore *)sharedStore;
- (NSDictionary *)myTribesVybes;

- (void)refreshTribes;
- (void)syncWithCloudForTribe:(NSString *)tribeName;
- (NSString *)videoPathAtIndex:(NSInteger)index forTribe:(NSString *)name;
- (NSString *)thumbPathAtIndex:(NSInteger)index forTribe:(NSString *)name;;
- (NSString *)myTribesArchivePath;
- (void)listVybes;
- (BOOL)saveChanges;

@end
