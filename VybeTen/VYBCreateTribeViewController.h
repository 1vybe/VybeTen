//
//  VYBCreateTribeViewController.h
//  VybeTen
//
//  Created by jinsuk on 5/5/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VYBCreateTribeViewControllerDelegate <NSObject>

- (void)createdTribe:(PFObject *)aTribe;

@end

@interface VYBCreateTribeViewController : UIViewController

@property (nonatomic, strong) id <VYBCreateTribeViewControllerDelegate> delegate;

@end
