//
//  VYBOldZoneFinder.m
//  VybeTen
//
//  Created by jinsuk on 10/30/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBOldZoneFinder.h"
#import "VYBAppDelegate.h"

@implementation VYBOldZoneFinder {
    NSString *clientID;
    NSString *clientSecret;

    NSInteger numOfResults;

    NSString *searchURL;
    
    NSURLSession *session;
}
- (id)init {
    self = [super init];
    if (self) {
        clientID = @"O3P21TKG3FF1U11LDHT52PA50WLFPCBZUNHKBNK0OJRCOF12";
        clientSecret = @"JJ5VR1JFDUSIG0LBDKPFXFHUP3HACC004YDXSOZ4YZFRCMIB";
        
        numOfResults = 10;
        
        searchURL = @"https://api.foursquare.com/v2/venues/search?";
        searchURL = [searchURL stringByAppendingString:@"client_id=\(clientID)"];
        searchURL = [searchURL stringByAppendingString:@"&client_secret=\(clientSecret)"];
        searchURL = [searchURL stringByAppendingString:@"&intent=checkin"];
        searchURL = [searchURL stringByAppendingString:@"&v=20130815"]; // this is a required field
    
    
        session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    }
    return self;
}

- (void)findZoneNearLocationInBackgroundWithLatitude:(double)latitude longitude:(double)longitude completionHandler:(void (^)(NSArray *results, NSError *error))completionBlock {
       //searchURL = [searchURL stringByAppendingString:@"&limit=\(numOfResults)"];
       //searchURL = [searchURL stringByAppendingString:@"&ll=\(latitude),\(longitude)"];
    
    searchURL = @"https://api.foursquare.com/v2/venues/search?client_id=O3P21TKG3FF1U11LDHT52PA50WLFPCBZUNHKBNK0OJRCOF12&client_secret=JJ5VR1JFDUSIG0LBDKPFXFHUP3HACC004YDXSOZ4YZFRCMIB&intent=checkin&v=20130815&limit=10";
    searchURL = [searchURL stringByAppendingFormat:@"&ll=%f,%f", latitude, longitude];
    
    NSURLSessionTask *task = [session dataTaskWithURL:[NSURL URLWithString:searchURL] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            if (statusCode == 200) {
                NSArray *zones = [self generateZonesFromData:data];
                completionBlock(zones, nil);
            } else {
                completionBlock(nil, error);
            }
        }
        else {
            completionBlock(nil, error);
        }
    }];
    
    [task resume];
}

- (NSArray *)generateZonesFromData:(NSData *)data {
NSMutableArray *zones = [[NSMutableArray alloc] init];
    NSError *jsonError;

    NSDictionary *jsonObj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
    if (!jsonError) {
        NSDictionary *response = jsonObj[@"response"];
        NSArray *venues = response[@"venues"];
        for (NSDictionary *aVenue in venues) {
            VYBZone *aZone = [[VYBZone alloc] initWithFoursquareVenue:aVenue];
            [zones addObject:aZone];
        }
        return zones;
    }
    
    return nil;
}
@end
