//
//  AVAsset+VideoOrientation.h
//  VybeTen
//
//  Created by jinsuk on 8/22/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

typedef enum {
    VYBVideoOrientationUp = 1,             //Device starts recording in Portrait
	VYBVideoOrientationDown = 2,             //Device starts recording in Portrait upside down
    VYBVideoOrientationRight = 3,            //Device Landscape Right (home button on the Right side)
    VYBVideoOrientationLeft = 4,             //Device Landscape Left  (home button on the left side)
    VYBVideoOrientationNotFound = 99     //An Error occurred or AVAsset doesn't contains video track
} VYBVideoOrientation;

@interface AVAsset (VideoOrientation)

/**
 Returns a LBVideoOrientation that is the orientation
 of the iPhone / iPad whent starst recording
 
 @return A LBVideoOrientation that is the orientation of the video
 */
@property (nonatomic, readonly) AVCaptureVideoOrientation videoOrientation;

@end