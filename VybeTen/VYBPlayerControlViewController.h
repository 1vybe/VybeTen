//
//  VYBPlayerControlViewController.h
//  VybeTen
//
//  Created by jinsuk on 10/6/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VYBPlayerControlViewController : UIViewController
@property (nonatomic) PFObject *currRegion;
@property (nonatomic, copy) NSArray *vybePlaylist;
@property (nonatomic) NSInteger currVybeIndex;

- (void)beginPlayingFrom:(NSInteger)from;
- (void)playNextItem;

@end
