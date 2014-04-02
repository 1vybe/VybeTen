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

- (BOOL)refreshTribes;
- (BOOL)syncWithCloudForTribe:(NSString *)tribeName;
- (BOOL)addNewTribe:(NSString *)tribeName;
- (NSString *)videoPathAtIndex:(NSInteger)index forTribe:(NSString *)name;
- (NSString *)thumbPathAtIndex:(NSInteger)index forTribe:(NSString *)name;
- (NSString *)thumbPathAtIndex:(NSInteger)index forTribe:(NSString *)name alreadyDownloaded:(BOOL)down;
- (NSString *)myTribesArchivePath;
- (NSArray *)tribes;
- (NSArray *)downloadedVybesForTribe:(NSString *)tribe;
- (void)analyzeTribe:(NSString *)tribe;
- (void)listVybes;
- (BOOL)clear;
- (BOOL)saveChanges;

@end
