//
//  AVAsset+VideoOrientation.m
//  VybeTen
//
//  Created by jinsuk on 8/22/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "AVAsset+VideoOrientation.h"


static inline CGFloat RadiansToDegrees(CGFloat radians) {
    return radians * 180 / M_PI;
};

@implementation AVAsset (VideoOrientation)
@dynamic videoOrientation;

- (VYBVideoOrientation)videoOrientation
{
    NSArray *videoTracks = [self tracksWithMediaType:AVMediaTypeVideo];
    if ([videoTracks count] == 0) {
        return VYBVideoOrientationNotFound;
    }
    
    AVAssetTrack* videoTrack    = [videoTracks objectAtIndex:0];
    CGAffineTransform txf       = [videoTrack preferredTransform];
    CGFloat videoAngleInDegree  = RadiansToDegrees(atan2(txf.b, txf.a));
    
	VYBVideoOrientation orientation = 0;
	switch ((int)videoAngleInDegree) {
		case 0:
			orientation = VYBVideoOrientationRight;
			break;
		case 90:
			orientation = VYBVideoOrientationUp;
			break;
		case 180:
			orientation = VYBVideoOrientationLeft;
			break;
		case -90:
			orientation	= VYBVideoOrientationDown;
			break;
        default:
            orientation = VYBVideoOrientationNotFound;
            break;
	}
	
	return orientation;
}


@end