//
//  VYBPermissionViewController.m
//  VybeTen
//
//  Created by jinsuk on 7/16/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBPermissionViewController.h"
#import <CoreLocation/CoreLocation.h>

@interface VYBPermissionViewController ()
@property (nonatomic, strong) IBOutlet UIButton *okButton;
@property (nonatomic, strong) IBOutlet UIButton *laterButton;
@property (nonatomic, strong) IBOutlet UITextField *textField1;
@property (nonatomic, strong) IBOutlet UITextField *textField2;
@property (nonatomic, strong) IBOutlet UITextField *textField3;
@property (nonatomic, strong) CLLocationManager *locationManager;

- (IBAction)okButtonPressed:(id)sender;
- (IBAction)laterButtonPressed:(id)sender;

@end

@implementation VYBPermissionViewController {
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.textField1 setFont:[UIFont fontWithName:@"AvenirLTStd-Book.otf" size:40.0]];
    [self.textField2 setFont:[UIFont fontWithName:@"AvenirLTStd-Book.otf" size:16.0]];
    [self.textField3 setFont:[UIFont fontWithName:@"AvenirLTStd-Book.otf" size:16.0]];

    // Do any additional setup after loading the view from its nib.
}

- (IBAction)okButtonPressed:(id)sender {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    //[self.locationManager startUpdatingLocation];
    // for iOS 8
    [self.locationManager requestAlwaysAuthorization];
}

- (IBAction)laterButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorized || status == kCLAuthorizationStatusDenied) {
        [self.locationManager stopUpdatingLocation];
        self.locationManager = nil;
        [self.navigationController popViewControllerAnimated:NO];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
