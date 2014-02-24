//
//  VYBVybe.m
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 24..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import "VYBVybe.h"


@implementation VYBVybe

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        [self setVideoPath:[aDecoder decodeObjectForKey:@"videoPath"]];
        [self setThumbnailImg:[aDecoder decodeObjectForKey:@"thumbnanilImg"]];
        [self setTimeStamp:[aDecoder decodeObjectForKey:@"timeStamp"]];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:videoPath forKey:@"videoPath"];
    [aCoder encodeObject:thumbnailImg forKey:@"thumbnailImg"];
    [aCoder encodeObject:timeStamp forKey:@"timeStamp"];
}

- (void)setVideoPath:(NSString *)vidPath {
    videoPath = vidPath;
}

- (void)setThumbnailImg:(UIImage *)thumbImg {
    thumbnailImg = thumbImg;
}

- (void)setTimeStamp:(NSDate *)date {
    timeStamp = date;
}

- (UIImage *)getThumbnail {
    return thumbnailImg;
}
- (NSData *)getVideo {
    return [[NSData alloc] initWithContentsOfFile:videoPath];
}


@end
