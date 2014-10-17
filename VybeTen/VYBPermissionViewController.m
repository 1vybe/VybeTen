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

@end

@implementation VYBPermissionViewController {
    CLLocationManager *_locationManager;
    BOOL _isLatestOS;
}

- (id)init {
    self = [super init];
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
    
    [self.view setBackgroundColor:[UIColor clearColor]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self checkPermissionSettings];
}


#pragma mark - Permissions

- (void)checkPermissionSettings {

    [self checkPermissionForAudioAccess];
}

- (void)checkPermissionForAudioAccess {
    NSString *title = [[NSString alloc] init];
    NSString *message = [[NSString alloc] init];
    
    if ([[AVAudioSession sharedInstance] recordPermission] == AVAudioSessionRecordPermissionGranted) {
        [[NSUserDefaults standardUserDefaults] setObject:kVYBUserDefaultsAudioAccessPermissionGrantedKey forKey:kVYBUserDefaultsAudioAccessPermissionKey];
    }
    
    NSString *audioPermission = [[NSUserDefaults standardUserDefaults] objectForKey:kVYBUserDefaultsAudioAccessPermissionKey];
    
    // iOS7 and prior
    if ( !_isLatestOS) {
        if ( [audioPermission isEqualToString:kVYBUserDefaultsAudioAccessPermissionDeniedKey]
            || ([[AVAudioSession sharedInstance] recordPermission] == AVAuthorizationStatusDenied) ) {
            title = @"Enable Audio Access";
            message = @"Please allow Vybe to access your microphone from Settings -> Privacy -> Microhpone";
            
            UIAlertView *mediaAlertView = [[UIAlertView alloc] initWithTitle:title
                                                                     message:message
                                                                    delegate:self
                                                           cancelButtonTitle:@"OK"
                                                           otherButtonTitles:nil];
            [mediaAlertView show];
        }
        else if ( [audioPermission isEqualToString:kVYBUserDefaultsAudioAccessPermissionUndeterminedKey] ) {
            UIAlertView *mediaAlertView = [[UIAlertView alloc] initWithTitle:title
                                                                     message:message
                                                                    delegate:self
                                                           cancelButtonTitle:@"Cancel"
                                                           otherButtonTitles:@"OK",nil];
            [mediaAlertView show];
        }
        else if ( [audioPermission isEqualToString:kVYBUserDefaultsAudioAccessPermissionGrantedKey] ) {
            [self checkPermissionForVideoAccess];
        }
    }
    // iOS8 and later
    else {
        if ( [audioPermission isEqualToString:kVYBUserDefaultsAudioAccessPermissionDeniedKey] ) {
            title = @"Enable Audio Access";
            message = @"Please allow Vybe to access your microphone from Settings -> Privacy -> Microhpone";
            
            UIAlertController *mediaAlertController = [UIAlertController alertControllerWithTitle:title
                                                                                          message:message
                                                                                   preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 [self checkPermissionForVideoAccess];
                                                             }];
            [mediaAlertController addAction:okAction];
            [self presentViewController:mediaAlertController animated:NO completion:nil];
        }
        else if ( [audioPermission isEqualToString:kVYBUserDefaultsAudioAccessPermissionUndeterminedKey] ) {      title = @"Audio Access";
            message = @"We'd like to record what you hear when you are vybing";
            
            UIAlertController *mediaAlertController = [UIAlertController alertControllerWithTitle:title
                                                                                          message:message
                                                                                   preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action) {
                                                                     [self checkPermissionForVideoAccess];
                                                                 }];
            [mediaAlertController addAction:cancelAction];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                                                                     if (granted) {
                                                                         [[NSUserDefaults standardUserDefaults] setObject:kVYBUserDefaultsAudioAccessPermissionGrantedKey forKey:kVYBUserDefaultsAudioAccessPermissionKey];
                                                                     } else {
                                                                         [[NSUserDefaults standardUserDefaults] setObject:kVYBUserDefaultsAudioAccessPermissionDeniedKey forKey:kVYBUserDefaultsAudioAccessPermissionKey];
                                                                     }

                                                                     [self checkPermissionForVideoAccess];
                                                                 }];
                                                             }];
            [mediaAlertController addAction:okAction];
            [self presentViewController:mediaAlertController animated:NO completion:nil];
        }
        else if ( [audioPermission isEqualToString:kVYBUserDefaultsAudioAccessPermissionGrantedKey] ) {
            [self checkPermissionForVideoAccess];
        }
    }
}

- (void)checkPermissionForVideoAccess {
    NSString *title = [[NSString alloc] init];
    NSString *message = [[NSString alloc] init];
    
    if ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusAuthorized) {
        [[NSUserDefaults standardUserDefaults] setObject:kVYBUserDefaultsVideoAccessPermissionGrantedKey forKey:kVYBUserDefaultsVideoAccessPermissionKey];
    }

    NSString *videoPermission = [[NSUserDefaults standardUserDefaults] objectForKey:kVYBUserDefaultsVideoAccessPermissionKey];

    // Video access denied
    if ( [videoPermission isEqualToString:kVYBUserDefaultsVideoAccessPermissionDeniedKey]
        || ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusDenied)) {
        
        title = @"Enable Video Access";
        message = @"Please allow Vybe to access your camera from Settings -> Privacy -> Camera";
        
        // iOS7 and prior
        if ( !_isLatestOS ) {
            UIAlertView *mediaAlertView = [[UIAlertView alloc] initWithTitle:title
                                                                     message:message
                                                                    delegate:self
                                                           cancelButtonTitle:@"OK"
                                                           otherButtonTitles:nil];
            [mediaAlertView show];
        }
        else {
            UIAlertController *mediaAlertController = [UIAlertController alertControllerWithTitle:title
                                                                                          message:message
                                                                                   preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 [self checkPermissionForLocationAccess];
                                                             }];
            [mediaAlertController addAction:okAction];
            [self presentViewController:mediaAlertController animated:NO completion:nil];
            
        }
    }
    else if ( [videoPermission isEqualToString:kVYBUserDefaultsVideoAccessPermissionUndeterminedKey] ) {
        title = @"Video Access";
        message = @"Vybe wants to access your camera to record your videos";
        
        // iOS7 and prior
        if ( !_isLatestOS ) {
            UIAlertView *mediaAlertView = [[UIAlertView alloc] initWithTitle:title
                                                                     message:message
                                                                    delegate:self
                                                           cancelButtonTitle:@"Cancel"
                                                           otherButtonTitles:@"OK",nil];
            [mediaAlertView show];
        }
        else {
            UIAlertController *mediaAlertController = [UIAlertController alertControllerWithTitle:title
                                                                                          message:message
                                                                                   preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                   style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction *action) {
                                                                     [self checkPermissionForLocationAccess];
                                                                 }];
            [mediaAlertController addAction:cancelAction];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                                                                     if (granted) {
                                                                         [[NSUserDefaults standardUserDefaults] setObject:kVYBUserDefaultsVideoAccessPermissionGrantedKey forKey:kVYBUserDefaultsVideoAccessPermissionKey];
                                                                     } else {
                                                                         [[NSUserDefaults standardUserDefaults] setObject:kVYBUserDefaultsVideoAccessPermissionDeniedKey forKey:kVYBUserDefaultsVideoAccessPermissionKey];
                                                                     }
                                                                     [self checkPermissionForLocationAccess];
                                                                 }];
                                                             }];
            [mediaAlertController addAction:okAction];
            [self presentViewController:mediaAlertController animated:NO completion:nil];
            
        }
    }
    else if ( [videoPermission isEqualToString:kVYBUserDefaultsVideoAccessPermissionGrantedKey] ) {
        [self checkPermissionForLocationAccess];
    }
}



- (void)checkPermissionForLocationAccess {
    if ( [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        // iOS7 and prior
        if ( !_isLatestOS ) {
            UIAlertView *locationAlertView = [[UIAlertView alloc] initWithTitle:@"Location Access"
                                                                        message:@"Allow access to your location so you know where you are vybing :)"
                                                                       delegate:self
                                                              cancelButtonTitle:@"Cancel"
                                                              otherButtonTitles:@"OK", nil];
            
            [locationAlertView show];
        } else {
            UIAlertController *locationAccessController = [UIAlertController alertControllerWithTitle:@"Location Access"
                                                                                              message:@"Allow access to your location so you know where you are vybing :)"
                                                                                       preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                   style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction *action) {
                                                                     [self.navigationController popViewControllerAnimated:NO];
                                                                 }];
            UIAlertAction *okayAction = [UIAlertAction actionWithTitle:@"OK"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction *action) {
                                                                   [_locationManager requestAlwaysAuthorization];
                                                               }];
            
            [locationAccessController addAction:cancelAction];
            [locationAccessController addAction:okayAction];
            
            [self presentViewController:locationAccessController animated:NO completion:nil];
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
                                                                handler:^(UIAlertAction *action) {
                                                                    [self.navigationController popViewControllerAnimated:NO];
                                                                }];
            [alertController addAction:alertAction];
            [self presentViewController:alertController animated:NO completion:nil];
        }
    }
    else {
        [self.navigationController popViewControllerAnimated:NO];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ( [[alertView title] isEqualToString:@"Enable Audio Access"] ) {
        [self checkPermissionForVideoAccess];
    }
    else if ( [[alertView title] isEqualToString:@"Enable Video Access"] ) {
        [self checkPermissionForLocationAccess];
    }
    else if ([[alertView title] isEqualToString:@"Enable Location Access"] ) {
        [self.navigationController popViewControllerAnimated:NO];
    }
    else if ( [[alertView title] isEqualToString:@"Location Access"] ) {
        if ( [[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"OK"] ) {
            [_locationManager startUpdatingLocation];
        }
        else {
            [self.navigationController popViewControllerAnimated:NO];
        }
    }
    else if ( [[alertView title] isEqualToString:@"Audio Access"] ) {
        if ( [[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"OK"] ) {
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                if (granted) {
                    [[NSUserDefaults standardUserDefaults] setObject:kVYBUserDefaultsAudioAccessPermissionGrantedKey forKey:kVYBUserDefaultsAudioAccessPermissionKey];
                } else {
                    [[NSUserDefaults standardUserDefaults] setObject:kVYBUserDefaultsAudioAccessPermissionDeniedKey forKey:kVYBUserDefaultsAudioAccessPermissionKey];
                }
                [self checkPermissionForVideoAccess];
            }];
        } else {
            [self checkPermissionForVideoAccess];
        }
    }
    else if ( [[alertView title] isEqualToString:@"Video Access"] ) {
        if ( [[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"OK"] ) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    [[NSUserDefaults standardUserDefaults] setObject:kVYBUserDefaultsVideoAccessPermissionGrantedKey forKey:kVYBUserDefaultsVideoAccessPermissionKey];
                } else {
                    [[NSUserDefaults standardUserDefaults] setObject:kVYBUserDefaultsVideoAccessPermissionDeniedKey forKey:kVYBUserDefaultsVideoAccessPermissionKey];
                }
                [self checkPermissionForLocationAccess];
            }];
        } else {
            [self checkPermissionForLocationAccess];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [_locationManager stopUpdatingLocation];
}



- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusNotDetermined)
        return;

    if (_locationManager)
        [_locationManager stopUpdatingLocation];
    
    [self.navigationController popViewControllerAnimated:NO];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
