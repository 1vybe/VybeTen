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
    NSMutableArray *myTribes;
    NSMutableDictionary *featuredTribes;
    NSMutableDictionary *trendingTribes;
    NSString *adId;
}
@property (nonatomic) AmazonS3Client *s3;

+ (VYBMyTribeStore *)sharedStore;
- (NSArray *)myTribes;
- (NSArray *)contributingTribes;
- (NSMutableDictionary *)featuredTribes;
- (NSMutableDictionary *)trendingTribes;
- (NSArray *)nonEmptyTribes;
- (NSArray *)tempFeaturedTribes;
- (NSArray *)tempTrendingTribes;
- (NSArray *)allMyTribes;

- (void)downloadFeaturedWithCompletion:(void (^)(NSError *err))block;
- (void)downloadTrendingWithCompletion:(void (^)(NSError *err))block;
- (void)setMyTribes:(NSMutableArray *)tribes;
- (void)refreshTribesWithCompletion:(void (^)(NSError *err))block;
- (void)syncWithCloudForTribe:(NSString *)name withCompletionBlock:(void (^)(NSError *err))block;
- (void)downloadTribeVybesFor:(VYBTribe *)tribe;
- (void)downloadFeaturedVybes;
- (void)downloadTrendingVybes;
- (BOOL)addNewTribe:(NSString *)tribeName;
- (NSString *)videoPathAtIndex:(NSInteger)index forTribe:(NSString *)name;
- (NSString *)thumbPathAtIndex:(NSInteger)index forTribe:(NSString *)name;
- (NSString *)thumbPathAtIndex:(NSInteger)index forTribe:(NSString *)name alreadyDownloaded:(BOOL)down;
- (NSString *)myTribesArchivePath;
- (NSDateFormatter *)presetDateFormatter;
//- (NSArray *)tribes;
- (BOOL)hasTribe:(NSString *)name;
- (VYBTribe *)tribe:(NSString *)name;
//- (void)analyzeTribe:(NSString *)tribe;
- (void)listVybes;
//- (BOOL)clear;
- (BOOL)saveChanges;

@end
