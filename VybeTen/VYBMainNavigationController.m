//
//  VYBMainNavigationController.m
//  VybeTen
//
//  Created by jinsuk on 3/28/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBMainNavigationController.h"

@implementation VYBMainNavigationController
@synthesize bottomBar = _bottomBar;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.bottomBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.width - 40, self.view.bounds.size.height, 40)];
        [self.bottomBar setShadowImage:[[UIImage alloc] init] forToolbarPosition:UIBarPositionBottom];
        [self.bottomBar setBarStyle:UIBarStyleBlack];
        //[self.bottomBar setTranslucent:YES];

        [self.view addSubview:self.bottomBar];
    }
    return self;
}

- (void)captureVybe:(id)sender {
    [self popToRootViewControllerAnimated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
