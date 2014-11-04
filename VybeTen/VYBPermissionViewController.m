//
//  VYBPermissionViewController.m
//  VybeTen
//
//  Created by jinsuk on 7/16/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBPermissionViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface VYBPermissionViewController ()
@property (nonatomic, weak) IBOutlet UIImageView *promptView;
- (IBAction)confirmButtonPressed:(id)sender;
@end

typedef NS_ENUM(NSInteger, VYBPermissionStage) {
    VYBPermissionStageNone = 0,
    VYBPermissionStageAudioGranted,
    VYBPermissionStageVideoGranted,
    VYBPermissionStageAllGranted,
};

@implementation VYBPermissionViewController {
    CLLocationManager *_locationManager;
    
    VYBPermissionStage _currentStage;
    
    BOOL _isLatestOS;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _locationManager = [[CLLocationManager alloc] init];
        [_locationManager setDelegate:self];
        _isLatestOS = [_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _currentStage = VYBPermissionStageNone;
    
    [self checkPermissionSettings];
}


#pragma mark - Permissions

- (void)checkPermissionSettings {
    BOOL locationGranted = NO;
    // In case prompt was asked from unexpected routes and the user responded, we need to update
    if ( _isLatestOS ) {
        if ([[AVAudioSession sharedInstance] recordPermission] == AVAudioSessionRecordPermissionGranted) {
            [[NSUserDefaults standardUserDefaults] setObject:kVYBUserDefaultsAudioAccessPermissionGrantedKey forKey:kVYBUserDefaultsAudioAccessPermissionKey];
        }
        
        if ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusAuthorized) {
            [[NSUserDefaults standardUserDefaults] setObject:kVYBUserDefaultsVideoAccessPermissionGrantedKey forKey:kVYBUserDefaultsVideoAccessPermissionKey];
        }
        
        locationGranted = (([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)
                           || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways);
    } else {
        locationGranted = ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized);
    }
    
    NSString *micPermission = [[NSUserDefaults standardUserDefaults] objectForKey:kVYBUserDefaultsAudioAccessPermissionKey];
    NSString *cameraPermission = [[NSUserDefaults standardUserDefaults] objectForKey:kVYBUserDefaultsVideoAccessPermissionKey];
    
    if ( [micPermission isEqualToString:kVYBUserDefaultsAudioAccessPermissionGrantedKey] ) {
        _currentStage = VYBPermissionStageAudioGranted;
    }
    if ( (_currentStage > VYBPermissionStageNone) &&
        [cameraPermission isEqualToString:kVYBUserDefaultsVideoAccessPermissionGrantedKey]) {
        _currentStage = VYBPermissionStageVideoGranted;
    }
    if ( (_currentStage > VYBPermissionStageVideoGranted) && locationGranted)
        _currentStage = VYBPermissionStageAllGranted;
    
    [self displayPromptAtStage:_currentStage];
}

- (void)displayPromptAtStage:(NSInteger)stage {
    if (stage == VYBPermissionStageAllGranted) {
        [self.navigationController popViewControllerAnimated:NO];
    }
    if (stage == VYBPermissionStageNone) {
        [self.promptView setImage:[UIImage imageNamed:@"permission_camera_and_mic.png"]];
        return;
    }
    if (stage == VYBPermissionStageAudioGranted) {
        [self.promptView setImage:[UIImage imageNamed:@"permission_camera_and_mic.png"]];
        return;
    }
    if (stage == VYBPermissionStageVideoGranted) {
        [self.promptView setImage:[UIImage imageNamed:@"permission_location.png"]];
        return;
    }
}

- (IBAction)confirmButtonPressed:(id)sender {
    if (_currentStage == VYBPermissionStageNone) {
        [self requestAudioPermission];
    } else if (_currentStage == VYBPermissionStageAudioGranted) {
        [self requestVideoPermission];
    } else if (_currentStage == VYBPermissionStageVideoGranted) {
        [self requestLocationPermission];
    }
}

- (void)requestAudioPermission {
    NSString *micPermission = [[NSUserDefaults standardUserDefaults] objectForKey:kVYBUserDefaultsAudioAccessPermissionKey];
    if ( [micPermission isEqualToString:kVYBUserDefaultsAudioAccessPermissionUndeterminedKey] ) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            if (granted) {
                [[NSUserDefaults standardUserDefaults] setObject:kVYBUserDefaultsAudioAccessPermissionGrantedKey forKey:kVYBUserDefaultsAudioAccessPermissionKey];
                // you only move to next stage if you agreed
                [self requestVideoPermission];
                // you moved on to next stage
                _currentStage = VYBPermissionStageAudioGranted;
            } else {
                [[NSUserDefaults standardUserDefaults] setObject:kVYBUserDefaultsAudioAccessPermissionDeniedKey forKey:kVYBUserDefaultsAudioAccessPermissionKey];
            }
        }];
    }
    
    else if ([micPermission isEqualToString:kVYBUserDefaultsAudioAccessPermissionDeniedKey]) {
        NSString *title = @"Enable Audio Access";
        NSString *message = @"Please allow Vybe to access your microphone from Settings -> Privacy -> Microhpone";
        
        if ( _isLatestOS ) {
            UIAlertController *mediaAlertController = [UIAlertController alertControllerWithTitle:title
                                                                                          message:message
                                                                                   preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];
            [mediaAlertController addAction:okAction];
            [self presentViewController:mediaAlertController animated:NO completion:nil];
        }
        else {
            UIAlertView *mediaAlertView = [[UIAlertView alloc] initWithTitle:title
                                                                     message:message
                                                                    delegate:self
                                                           cancelButtonTitle:@"OK"
                                                           otherButtonTitles:nil];
            [mediaAlertView show];
        }
    }
}

- (void)requestVideoPermission {
    NSString *cameraPermission = [[NSUserDefaults standardUserDefaults] objectForKey:kVYBUserDefaultsVideoAccessPermissionKey];
    
    if ([cameraPermission isEqualToString:kVYBUserDefaultsVideoAccessPermissionUndeterminedKey]) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                [[NSUserDefaults standardUserDefaults] setObject:kVYBUserDefaultsVideoAccessPermissionGrantedKey forKey:kVYBUserDefaultsVideoAccessPermissionKey];
                
                _currentStage = VYBPermissionStageVideoGranted;
                // change the image view accordingly
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.promptView.alpha = 0.0f;
                    [self.promptView setImage:[UIImage imageNamed:@"permission_location.png"]];
                    [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                        self.promptView.alpha = 1.0f;
                    } completion:nil];
                });
            } else {
                [[NSUserDefaults standardUserDefaults] setObject:kVYBUserDefaultsVideoAccessPermissionDeniedKey forKey:kVYBUserDefaultsVideoAccessPermissionKey];
            }
        }];
    }
    else if ( [cameraPermission isEqualToString:kVYBUserDefaultsVideoAccessPermissionDeniedKey] ) {
        NSString *title = @"Enable Video Access";
        NSString *message = @"Please allow Vybe to access your camera from Settings -> Privacy -> Camera";
        
        if ( _isLatestOS ) {
            UIAlertController *mediaAlertController = [UIAlertController alertControllerWithTitle:title
                                                                                                message:message
                                                                                       preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];
            [mediaAlertController addAction:okAction];
            [self presentViewController:mediaAlertController animated:NO completion:nil];
                
        }
        else {
            UIAlertView *mediaAlertView = [[UIAlertView alloc] initWithTitle:title
                                                                     message:message
                                                                    delegate:self
                                                           cancelButtonTitle:@"OK"
                                                           otherButtonTitles:nil];
            [mediaAlertView show];
        }
    }
}

- (void)requestLocationPermission {
    if ( [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        // iOS7 and prior
        if ( _isLatestOS ) {
            [_locationManager requestAlwaysAuthorization];
        }
        else {
            [_locationManager startUpdatingLocation];
        }
    }
    else if (([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) || ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied)) {
        if ( !_isLatestOS ) {
            UIAlertView *locationServiceAlert = [[UIAlertView alloc] initWithTitle:@"Enable Location Service"
                                                                           message:@"Please allow Vybe to access your location from Settings -> Privacy -> Location Services"
                                                                          delegate:self
                                                                 cancelButtonTitle:@"OK"
                                                                 otherButtonTitles:nil];
            [locationServiceAlert show];
        }
        else {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Enable Location Service"
                                                                                     message:@"Please allow Vybe to access your location from Settings -> Privacy -> Location Services" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel
                                                                handler:nil];
            [alertController addAction:alertAction];
            [self presentViewController:alertController animated:NO completion:nil];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [_locationManager stopUpdatingLocation];
}



- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self.navigationController popViewControllerAnimated:NO];
            return;
        default:
            return;

    }
}


- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
