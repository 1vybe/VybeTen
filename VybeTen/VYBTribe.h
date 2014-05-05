//
//  VYBTribe.h
//  VybeTen
//
//  Created by jinsuk on 4/9/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VYBVybe.h"
#import "VYBS3Connector.h"

@interface VYBTribe : NSObject <NSCoding> {
    NSString *tribeName;
    BOOL open;
    NSMutableArray *vybes;
    NSMutableArray *users;
    NSMutableArray *syncs;
}

@property (nonatomic) VYBS3Connector *s3Connector;

- (id)initWithTribeName:(NSString *)name;

- (void)setTribeName:(NSString *)name;
- (void)setOpen:(BOOL)op;
- (void)setVybes:(NSMutableArray *)vys;
- (void)setUsers:(NSMutableArray *)usrs;
- (void)setSyncs:(NSMutableArray *)s;
- (NSString *)tribeName;
- (BOOL)isOpen;
- (NSMutableArray *)vybes;
- (NSMutableArray *)users;
- (NSMutableArray *)syncs;
- (void)stopOldConnector;

- (void)addVybe:(VYBVybe *)v;
- (VYBVybe *)vybeWithKey:(NSString *)vyKey;
- (BOOL)hasDownloadingVybe;
- (VYBVybe *)oldestVybeToBeDownloaded;
- (VYBVybe *)newestVybeTobeDownloaded;
- (VYBVybe *)newestUnwatchedVybeTobeDownloaded;
- (NSMutableArray *)downloadedVybes;
- (void)changeDownStatusFor:(NSString *)vyKey withStatus:(BOOL)down;
@end
