//
//  VYBPlayerControlViewController.h
//  VybeTen
//
//  Created by jinsuk on 10/6/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VYBPlayerControlViewController : UIViewController
- (id)initWithPageIndex:(NSInteger)pageIndex;
- (NSInteger)pageIndex;

@property (nonatomic) PFObject *currRegion;
@property (nonatomic, copy) NSArray *vybePlaylist;
@property (nonatomic) NSInteger currVybeIndex;
- (void)beginPlayingFrom:(NSInteger)from;
- (void)playNextItem;
- (void)playNextZoneVideo;

@end
