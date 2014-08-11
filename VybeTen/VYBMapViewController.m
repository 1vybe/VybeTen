//
//  VYBMapViewController.m
//  VybeTen
//
//  Created by jinsuk on 8/6/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "VYBMapViewController.h"

@interface VYBMapViewController ()
@property (nonatomic, strong) MKMapView *mapView;
@end

@implementation VYBMapViewController {
    UIButton *captureButton;
}

- (void)dealloc {
    _mapView = nil;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Hide status bar
    [self setNeedsStatusBarAppearanceUpdate];
    
    _mapView = [[MKMapView alloc] init];
    _mapView.delegate = self;
    [self.view addSubview:_mapView];
    
    // Adding CAPTURE button
    CGRect frame = CGRectMake(self.view.bounds.size.height - 70, self.view.bounds.size.width - 70, 70, 70);
    captureButton = [[UIButton alloc] initWithFrame:frame];
    [captureButton setImage:[UIImage imageNamed:@"button_capture.png"] forState:UIControlStateNormal];
    [captureButton addTarget:self action:@selector(captureButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:captureButton];
    
    MKPolygon *aPolygon;
    [_mapView addOverlay:aPolygon level:MKOverlayLevelAboveRoads];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [_mapView setFrame:self.view.frame];
}

#pragma mark - MKMapViewDelegate



- (void)captureButtonPressed {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    _mapView = nil;
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
