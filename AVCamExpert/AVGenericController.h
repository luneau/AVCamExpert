//
//  AVGenericController.h
//  AVCamExpert
//
//  Created by Sébastien Luneau on 01/12/2015.
//  Copyright © 2016 Matchpix. All rights reserved.
//

@import UIKit;
@import AVFoundation;
@import GLKit;

#define YUV_BUFFER 1
typedef void (^AVGenericControllerBlock)(NSError* error);
#import "StreamSource.h"
#import "AVPreviewView.h"
typedef NS_ENUM( NSInteger, AVCamManualSetupResult ) {
    AVCamManualSetupResultSuccess,
    AVCamManualSetupResultCameraNotAuthorized,
    AVCamManualSetupResultSessionConfigurationFailed
};

@interface AVGenericController : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic,strong) AVCaptureSession * captureSession;
@property (strong, nonatomic) NSArray * captureDevices;
@property (strong, nonatomic) AVCaptureDeviceInput * captureInput;
@property (strong, nonatomic) AVCaptureVideoDataOutput * captureOutput;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (strong, nonatomic) AVCaptureDevice *videoDevice;
@property (strong, nonatomic) AVCaptureConnection *videoConnection;
@property (assign, nonatomic) NSInteger currentCameraIndex;
@property (nonatomic) NSArray<StreamSource*>* sources;
@property (nonatomic) StreamSource* currentSource;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCamManualSetupResult setupResult;

@property (nonatomic,weak) id<AVCaptureVideoDataOutputSampleBufferDelegate> delegate;

+(id) AVGenericControllerWithPreviewLayer:(AVPreviewView*) preview withPosition:(AVCaptureDevicePosition) position completion:(AVGenericControllerBlock)completion;
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position;
- (void) setCameraWithPosition:(AVCaptureDevicePosition) position;
@end
