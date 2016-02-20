//
//  AVGenericController.m
//  AVCamExpert
//
//  Created by Sébastien Luneau on 01/12/2015.
//  Copyright © 2016 Matchpix. All rights reserved.
//

#import "AVGenericController.h"

@implementation AVGenericController

+(id) AVGenericControllerWithPreviewLayer:(AVPreviewView*) preview withPosition:(AVCaptureDevicePosition) position completion:(AVGenericControllerBlock)completion{
    AVGenericController *controller = [[AVGenericController alloc] init];
    if (controller){
        controller.currentCameraIndex = 0;
        controller.captureSession = [[AVCaptureSession alloc] init];
        controller.captureDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        if (controller.captureDevices.count == 0) return controller;
        controller.videoDevice = [controller.captureDevices objectAtIndex:0];
        controller.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
        controller.setupResult = AVCamManualSetupResultSuccess;
        preview.session = controller.captureSession;
        
        // Check video authorization status. Video access is required and audio access is optional.
        // If audio access is denied, audio is not recorded during movie recording.
        switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] )
        {
            case AVAuthorizationStatusAuthorized:
            {
                // The user has previously granted access to the camera.
                break;
            }
            case AVAuthorizationStatusNotDetermined:
            {
                // The user has not yet been presented with the option to grant video access.
                // We suspend the session queue to delay session setup until the access request has completed to avoid
                // asking the user for audio access if video access is denied.
                // Note that audio access will be implicitly requested when we create an AVCaptureDeviceInput for audio during session setup.
                dispatch_suspend( controller.sessionQueue );
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                    if ( ! granted ) {
                        controller.setupResult = AVCamManualSetupResultCameraNotAuthorized;
                    }
                    dispatch_resume( controller.sessionQueue );
                }];
                break;
            }
            default:
            {
                // The user has previously denied access.
                controller.setupResult = AVCamManualSetupResultCameraNotAuthorized;
                break;
            }
        }
        //Add input to session
        NSError *err = nil;
        AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[controller cameraWithPosition:position] error:&err];
        if(!newVideoInput || err)
        {
            NSLog(@"Error creating capture device input: %@", err.localizedDescription);
        }
        else
        {
            controller.captureInput = newVideoInput;
        }

        // Setup the capture session.
        // In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
        // Why not do all of this on the main queue?
        // Because -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue
        // so that the main queue isn't blocked, which keeps the UI responsive.
        dispatch_async( controller.sessionQueue, ^{
            if ( controller.setupResult != AVCamManualSetupResultSuccess ) {
                return;
            }
            NSError *error = nil;
            if ( ! controller.captureInput ) {
                NSLog( @"Could not create video device input: %@", error );
                
            }
            [controller.captureSession beginConfiguration];
            
            dispatch_async( dispatch_get_main_queue(), ^{
                // Why are we dispatching this to the main queue?
                // Because AVCaptureVideoPreviewLayer is the backing layer for AAPLPreviewView and UIView
                // can only be manipulated on the main thread.
                // Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
                // on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                
                // Use the status bar orientation as the initial video orientation. Subsequent orientation changes are handled by
                // -[viewWillTransitionToSize:withTransitionCoordinator:].
                UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
                AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
                if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
                    initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
                }
                AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)preview.layer;
                previewLayer.connection.videoOrientation = initialVideoOrientation;
            } );
            
            AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
            AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
            
            if ( ! audioDeviceInput ) {
                NSLog( @"Could not create audio device input: %@", error );
            }
            
            if ( [controller.captureSession canAddInput:audioDeviceInput] ) {
                [controller.captureSession addInput:audioDeviceInput];
            }
            else {
                NSLog( @"Could not add audio device input to the session" );
            }
            
            controller.captureInput = [AVCaptureDeviceInput deviceInputWithDevice:controller.videoDevice error:&error];
            if (error){
                NSLog(@"Couldn't create video input");
            }
            controller.captureOutput = [[AVCaptureVideoDataOutput alloc] init];
            controller.captureOutput.alwaysDiscardsLateVideoFrames = YES;
            
            // Set the video output to store frame in BGRA (It is supposed to be faster)
            //NSDictionary* videoSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]};
            NSDictionary* videoSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]};
            //AVCaptureConnection *conn = [captureOutput connectionWithMediaType:AVMediaTypeVideo];
            
            [controller.captureOutput setVideoSettings:videoSettings];
            /*We create a serial queue to handle the processing of our frames*/
            //controller.sessionQueue = dispatch_queue_create("com.matchpix.AVCamExpert", NULL);
            [controller.captureOutput setSampleBufferDelegate:controller queue:dispatch_get_main_queue()];
            [controller.captureSession addInput:controller.captureInput];
            [controller.captureSession addOutput:controller.captureOutput];
            
            /*controller.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
            if ( [controller.captureSession canAddOutput:controller.movieFileOutput] ) {
                [controller.captureSession addOutput:controller.movieFileOutput];
                AVCaptureConnection *connection = [controller.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
                if ( connection.isVideoStabilizationSupported ) {
                    connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
                }
            }
            else {
                NSLog( @"Could not add movie file output to the session" );
                controller.movieFileOutput = nil;
                controller.setupResult = AVCamManualSetupResultSessionConfigurationFailed;
            }*/
            controller.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
            if ( [controller.captureSession canAddOutput:controller.stillImageOutput] ) {
                [controller.captureSession addOutput:controller.stillImageOutput];
                controller.stillImageOutput = controller.stillImageOutput;
                controller.stillImageOutput.outputSettings = @{ AVVideoCodecKey : AVVideoCodecJPEG };
                controller.stillImageOutput.highResolutionStillImageOutputEnabled = YES;
            }else {
                NSLog( @"Could not add still image output to the session" );
                controller.setupResult = AVCamManualSetupResultSessionConfigurationFailed;
                controller.stillImageOutput = nil;
            }
            
            [controller.captureSession commitConfiguration];
            
            controller.sources = [StreamSource availableSources:controller.videoDevice];
            for (StreamSource* source in controller.sources){
                if (source.format == controller.videoDevice.activeFormat){
                    controller.currentSource = source;
                }
            }
            dispatch_async( dispatch_get_main_queue(), ^{
            completion(error);
            });
            
        });
    }
    return controller;
}
// Find a camera with the specified AVCaptureDevicePosition, returning nil if one is not found
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position) return device;
    }
    return nil;
}

- (void) setCameraWithPosition:(AVCaptureDevicePosition) position{
    //Indicate that some changes will be made to the session
    
    if(((AVCaptureDeviceInput*)[self.captureSession.inputs objectAtIndex:0]).device.position == position)
    {
        return;
    }

    [self.captureSession beginConfiguration];
    
    //Remove existing input
    [self.captureSession removeInput:self.captureInput];
    
    //Get new input
    AVCaptureDevice *newCamera = nil;
    newCamera = [self cameraWithPosition:position];
    
    
    //Add input to session
    NSError *err = nil;
    AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera error:&err];
    if(!newVideoInput || err)
    {
        NSLog(@"Error creating capture device input: %@", err.localizedDescription);
    }
    else
    {
        [self.captureSession addInput:newVideoInput];
    }
    
    //Commit all the configuration changes at once
    [self.captureSession commitConfiguration];
    self.captureInput = newVideoInput;
    self.videoDevice = newCamera;
    self.sources = [StreamSource availableSources:self.videoDevice];
    self.videoConnection = [self.captureOutput connectionWithMediaType:AVMediaTypeVideo];
    self.sources = [StreamSource availableSources:self.videoDevice];
    for (StreamSource* source in self.sources){
        if (source.format == self.videoDevice.activeFormat){
            self.currentSource = source;
        }
    }

}
#pragma mark -
#pragma mark AVCaptureSession delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    // glPreview deals with it
    [_delegate captureOutput:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
    
}

@end
