//
//  VYBVybeCell.h
//  VybeTen
//
//  Created by Kim Jin Su on 2014. 2. 26..
//  Copyright (c) 2014년 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VYBVybeCell : UITableViewCell {
    NSString *videoPath;
    NSString *thumbnailPath;
    NSString *date;
}

- (void)setThumbnailPath:(NSString *)path;
- (void)setVideoPath:(NSString *)path;
- (void)setDate:(NSDate *)date;
- (void)setContentView;
- (NSString *)getDate;

@end
