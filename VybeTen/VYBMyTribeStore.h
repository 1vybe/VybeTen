//
//  VYBMyTribeStore.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 3. 8..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSS3/AWSS3.h>
#import "VYBTribe.h"

@interface VYBMyTribeStore : NSObject <AmazonServiceRequestDelegate> {
    //NSArray *myTribes;
    NSMutableDictionary *trendingTribes;
    NSString *adId;
}
@property (nonatomic) AmazonS3Client *s3;
@property (nonatomic, retain) NSArray *myTribes;

+ (VYBMyTribeStore *)sharedStore;
- (NSMutableArray *)featuredTribes;

- (void)refreshTribesWithCompletion:(void (^)(NSError *err))block;
- (void)syncWithCloudForTribe:(NSString *)name withCompletionBlock:(void (^)(NSError *err))block;
- (void)downloadTribeVybesFor:(NSString *)tribeName withCompletion:(void (^)(NSError *err))block;
- (void)downloadTribeVybeFor:(VYBVybe *)v withCompletion:(void (^)(NSError *err))block;
- (void)downloadNextVybeOf:(VYBVybe *)v;
- (BOOL)addNewTribe:(NSString *)tribeName;
- (NSString *)videoPathAtIndex:(NSInteger)index forTribe:(NSString *)name;
- (NSString *)thumbPathAtIndex:(NSInteger)index forTribe:(NSString *)name;
- (NSString *)thumbPathAtIndex:(NSInteger)index forTribe:(NSString *)name alreadyDownloaded:(BOOL)down;
- (NSString *)myTribesArchivePath;
- (NSDateFormatter *)presetDateFormatter;
- (BOOL)hasTribe:(NSString *)name;
- (VYBTribe *)tribe:(NSString *)name;
- (void)listVybes;
- (BOOL)saveChanges;
- (void)saveThumbnailImageForVybe:(VYBVybe *)v;

//- (BOOL)clear;
//- (void)analyzeTribe:(NSString *)tribe;

@end
