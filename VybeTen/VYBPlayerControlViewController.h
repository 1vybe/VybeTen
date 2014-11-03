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

// Called should call this method inside the completion block when it is calling presentViewController: 
- (void)playVybes:(NSArray *)vybes;
- (void)playVybes:(NSArray *)vybes from:(NSInteger)idx;


@end
