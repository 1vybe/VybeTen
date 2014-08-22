//
//  VYBReplayViewController.m
//  VybeTen
//
//  Created by jinsuk on 7/11/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//

#import "VYBAppDelegate.h"
#import "VYBReplayViewController.h"
#import "VYBPlayerView.h"
#import "MBProgressHUD.h"
#import "VYBUtility.h"
#import "VYBMyVybeStore.h"
#import "VYBNavigationController.h"

@interface VYBReplayViewController ()

@end

@implementation VYBReplayViewController

- (void)dealloc {
    self.player = nil;
    self.playerView = nil;
}

- (void)loadView {
    UIView *darkBackground = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [darkBackground setBackgroundColor:[UIColor blackColor]];
    self.view = darkBackground;
    
    VYBPlayerView *playerView = [[VYBPlayerView alloc] init];
    
    [playerView setFrame:CGRectMake(0, 0, darkBackground.bounds.size.width, darkBackground.bounds.size.height)];
    
    self.playerView = playerView;
    
    self.player = [[AVPlayer alloc] init];
    
    [self.playerView setPlayer:self.player];
    
    [self.view addSubview:self.playerView];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Hide status bar
    [self setNeedsStatusBarAppearanceUpdate];
    
    // Device orientation detection
    UIDevice *iphone = [UIDevice currentDevice];
    [iphone beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceRotated:) name:UIDeviceOrientationDidChangeNotification object:iphone];
   
    // Adding CONFIRM button
    CGRect frame = CGRectMake(0, self.view.bounds.size.height - 70, 70, 70);
    self.acceptButton = [[UIButton alloc] initWithFrame:frame];
    [self.acceptButton setImage:[UIImage imageNamed:@"button_replay_accept.png"] forState:UIControlStateNormal];
    [self.acceptButton addTarget:self action:@selector(acceptButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.acceptButton];
    
    frame = CGRectMake(self.view.bounds.size.width - 70, self.view.bounds.size.height - 70, 70, 70);
    self.rejectButton = [[UIButton alloc] initWithFrame:frame];
    [self.rejectButton setImage:[UIImage imageNamed:@"button_replay_reject.png"] forState:UIControlStateNormal];
    [self.rejectButton addTarget:self action:@selector(rejectButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.rejectButton];
    
    // Adding toggle switch for private/public
    frame = CGRectMake(self.view.bounds.size.height - 150, self.view.bounds.size.width - 60, 130, 40);
    self.modeControl = [[UISegmentedControl alloc] initWithItems:@[@"Public", @"Private"]];
    [self.modeControl setFrame:frame];
    [self.modeControl addTarget:self action:@selector(modeChanged:) forControlEvents:UIControlEventValueChanged];
    // By default it's public
    self.isPublic = YES;
    //[self.view addSubview:self.modeControl];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.modeControl setSelectedSegmentIndex:(self.isPublic) ? 0 : 1];
    [self.modeControl setTintColor:(self.isPublic) ? [UIColor colorWithRed:0.0 green:191.0/255.0 blue:1.0 alpha:1.0] : [UIColor orangeColor]];
    
    NSURL *videoURL = [[NSURL alloc] initFileURLWithPath:[self.currVybe videoFilePath]];
    //NSLog(@"[Replay]videoURL is %@", videoURL);
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    self.currItem = [AVPlayerItem playerItemWithAsset:asset];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
    [self.player replaceCurrentItemWithPlayerItem:self.currItem];
    [self.player play];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.player pause];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.currItem];
}

- (void)playerItemDidReachEnd {
    [self.currItem seekToTime:kCMTimeZero];
    [self.player play];
}

- (void)acceptButtonPressed:(id)sender {
    NSData *video = [NSData dataWithContentsOfFile:[self.currVybe videoFilePath]];
    
    // here we do the magic to the video file to reduce its bitrate
    //[self resizeVideo:[self.currVybe videoFilePath]];
    
    PFFile *videoFile = [PFFile fileWithData:video];
    
    //NOTE: vybes are ALWAYS public now
    [self.currVybe setIsPublic:YES];
    PFObject *vybe = [self.currVybe parseObjectVybe];
    
    PFACL *vybeACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [vybeACL setPublicReadAccess:YES];
    vybe.ACL = vybeACL;
    
    if ( [(VYBAppDelegate *)[UIApplication sharedApplication].delegate isParseReachable] ) {
        UIProgressView *uploadProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        [uploadProgressView setFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50)];
        [self.navigationController.view addSubview:uploadProgressView];
        [videoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [vybe setObject:videoFile forKey:kVYBVybeVideoKey];
                [VYBUtility clearLocalCacheForVybe:self.currVybe];
                [vybe saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        NSLog(@"Posted");
                        [VYBUtility showToastWithImage:[UIImage imageNamed:@"button_check.png"] title:@"Posted"];
                    }
                    else {
                        NSLog(@"Saved");
                        [vybe saveEventually];
                        [VYBUtility showToastWithImage:[UIImage imageNamed:@"button_check.png"] title:@"Saved"];
                    }
                    [uploadProgressView removeFromSuperview];
                }];
            } else {
                [[VYBMyVybeStore sharedStore] addVybe:self.currVybe];
                [uploadProgressView removeFromSuperview];
                
                NSLog(@"Saved");
                [VYBUtility showToastWithImage:[UIImage imageNamed:@"button_check.png"] title:@"Saved"];
            }
        } progressBlock:^(int percentDone) {
            uploadProgressView.progress = percentDone / 100.0;
        }];
    } else {
        [[VYBMyVybeStore sharedStore] addVybe:self.currVybe];
    }
    
    // Update user lastVybeLocation and lastVybeTime field. lastVybeLocation is updated in captureVC didUpdateLocaton
    [[PFUser currentUser] setObject:self.currVybe.timeStamp forKey:kVYBUserLastVybedTimeKey];
    [[PFUser currentUser] saveInBackground];
    
    [self.navigationController popViewControllerAnimated:NO];
}


- (void)rejectButtonPressed:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:[self.currVybe videoFilePath]];
        
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtURL:outputURL error:&error];
        if (error) {
            NSLog(@"Failed to delete the cancelled vybe.");
        }
    });
    
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)resizeVideo:(NSString *)aVideoPath {
    NSString *newName = [aVideoPath stringByAppendingString:@".resized"];
    NSURL *fullPath = [NSURL fileURLWithPath:newName];
    NSURL *path = [NSURL fileURLWithPath:aVideoPath];
    
    
    NSError *error = nil;
    
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:fullPath fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(videoWriter);
    AVAsset *avAsset = [[AVURLAsset alloc] initWithURL:path options:nil] ;
    
    
    
    NSDictionary *videoCleanApertureSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSNumber numberWithInt:480], AVVideoCleanApertureWidthKey,
                                                [NSNumber numberWithInt:640], AVVideoCleanApertureHeightKey,
                                                [NSNumber numberWithInt:10], AVVideoCleanApertureHorizontalOffsetKey,
                                                [NSNumber numberWithInt:10], AVVideoCleanApertureVerticalOffsetKey,
                                                nil];
    
    
    NSDictionary *codecSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInt:1960000], AVVideoAverageBitRateKey,
                                   [NSNumber numberWithInt:24],AVVideoMaxKeyFrameIntervalKey,
                                   videoCleanApertureSettings, AVVideoCleanApertureKey,
                                   nil];
    
    
    
    NSDictionary *videoCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              AVVideoCodecH264, AVVideoCodecKey,
                                              codecSettings,AVVideoCompressionPropertiesKey,
                                              [NSNumber numberWithInt:480], AVVideoWidthKey,
                                              [NSNumber numberWithInt:640], AVVideoHeightKey,
                                              nil];
    
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput
                                            assetWriterInputWithMediaType:AVMediaTypeVideo
                                            outputSettings:videoCompressionSettings];
    
    NSParameterAssert(videoWriterInput);
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    videoWriterInput.expectsMediaDataInRealTime = YES;
    [videoWriter addInput:videoWriterInput];
    NSError *aerror = nil;
    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:avAsset error:&aerror];
    AVAssetTrack *videoTrack = [[avAsset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0];
    
    videoWriterInput.transform = videoTrack.preferredTransform;
    NSDictionary *videoOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    AVAssetReaderTrackOutput *asset_reader_output = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:videoOptions];
    [reader addOutput:asset_reader_output];
    //audio setup
    
    AVAssetWriterInput* audioWriterInput = [AVAssetWriterInput
                                            assetWriterInputWithMediaType:AVMediaTypeAudio
                                            outputSettings:nil];
    
    
    AVAssetReader *audioReader = [AVAssetReader assetReaderWithAsset:avAsset error:&error];
    AVAssetTrack* audioTrack = [[avAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    AVAssetReaderOutput *readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:nil];
    
    [audioReader addOutput:readerOutput];
    NSParameterAssert(audioWriterInput);
    NSParameterAssert([videoWriter canAddInput:audioWriterInput]);
    audioWriterInput.expectsMediaDataInRealTime = NO;
    [videoWriter addInput:audioWriterInput];
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    [reader startReading];
    dispatch_queue_t _processingQueue = dispatch_queue_create("assetAudioWriterQueue", NULL);
    [videoWriterInput requestMediaDataWhenReadyOnQueue:_processingQueue usingBlock:^{
        while ([videoWriterInput isReadyForMoreMediaData]) {
            
            CMSampleBufferRef sampleBuffer;
            
            if ([reader status] == AVAssetReaderStatusReading) {
                
                if(![videoWriterInput isReadyForMoreMediaData])
                    continue;
                
                sampleBuffer = [asset_reader_output copyNextSampleBuffer];
                NSLog(@"READING");
                
                if(sampleBuffer)
                    [videoWriterInput appendSampleBuffer:sampleBuffer];
                
                NSLog(@"WRITTING...");
            } else {
                [videoWriterInput markAsFinished];
                
                switch ([reader status]) {
                    case AVAssetReaderStatusReading:
                        // the reader has more for other tracks, even if this one is done
                        break;
                        
                    case AVAssetReaderStatusCompleted:
                        // your method for when the conversion is done
                        // should call finishWriting on the writer
                        //hook up audio track
                    {                                               
                        [videoWriter startSessionAtSourceTime:kCMTimeZero];
                        
                        break;
                    }
                    case AVAssetReaderStatusFailed:
                    {
                        [videoWriter cancelWriting];
                        break;
                    }
                }
                break;
            }
        }
    }];
}

- (void)modeChanged:(id)sender {
    self.isPublic = (self.modeControl.selectedSegmentIndex == 0);
    self.modeControl.tintColor = (self.isPublic) ? [UIColor colorWithRed:0.0 green:191.0/255.0 blue:1.0 alpha:1.0] : [UIColor orangeColor];
    if (self.isPublic) {
        NSLog(@"changed to public");
    }
}

#pragma mark - DeviceOrientation

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


- (void)deviceRotated:(NSNotification *)notification {
    UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
    double rotation = 0;
    switch (currentOrientation) {
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationUnknown:
            return;
        case UIDeviceOrientationPortrait:
            rotation = 0;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            rotation = -M_PI;
            break;
        case UIDeviceOrientationLandscapeLeft:
            rotation = M_PI_2;
            break;
        case UIDeviceOrientationLandscapeRight:
            rotation = -M_PI_2;
            break;
    }
    
    CGAffineTransform transform = CGAffineTransformMakeRotation(rotation);
    [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.acceptButton setTransform:transform];
        [self.rejectButton setTransform:transform];
    } completion:nil];
    
}


- (BOOL)prefersStatusBarHidden {
    return YES;
}


@end
