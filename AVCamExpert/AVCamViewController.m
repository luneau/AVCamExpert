//
//  ViewController.m
//  AVCamExpert
//
//  Created by Sébastien Luneau on 01/12/2015.
//  Copyright © 2015 Matchpix. All rights reserved.
//
static void * LensPositionContext = &LensPositionContext;
static void * ExposureDurationContext = &ExposureDurationContext;
static void * ISOContext = &ISOContext;
static void * ExposureTargetOffsetContext = &ExposureTargetOffsetContext;

//static const float kExposureDurationPower = 5; // Higher numbers will give the slider more sensitivity at shorter durations
//static const float kExposureMinimumDuration = 1.0/1000; // Limit exposure duration to a useful range


@import Photos;
@import WatchConnectivity;

#import "AVCamViewController.h"
#import "CALayerPreviewView.h"

#import "GLPreviewView.h"
#import "StreamSource.h"
#import "OutlinedLabel.h"
#import "AVGenericController.h"
#import "JPSVolumeButtonHandler.h"
#import "WatchRemotePreview.h"


@interface AVCamViewController ()<WCSessionDelegate>
{
    size_t count;
    
    
}
@property (strong, nonatomic) AVGenericController* avGenericController;
@property (assign, nonatomic) NSInteger currentCameraIndex;

@property (weak, nonatomic) IBOutlet CALayerPreviewView *previewView;
@property (weak, nonatomic) IBOutlet UIButton *sizeButton;
@property (weak, nonatomic) IBOutlet UIButton *settingButton;
@property (weak, nonatomic) IBOutlet UIButton *frameRateButton;
@property (weak, nonatomic) IBOutlet UISwitch *flashSwitch;
@property (weak, nonatomic) IBOutlet OutlinedLabel *flashLabel;
@property (weak, nonatomic) IBOutlet OutlinedLabel *hdrLabel;
@property (weak, nonatomic) IBOutlet UISwitch *hdrSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *isSwitch;
@property (weak, nonatomic) IBOutlet OutlinedLabel *isLabel;
@property (weak, nonatomic) IBOutlet UIView *infoView;
@property (weak, nonatomic) IBOutlet OutlinedLabel *exposureLabel;
@property (weak, nonatomic) IBOutlet OutlinedLabel *isoLabel;

@property (weak, nonatomic) IBOutlet GLPreviewView *glPreview;
@property (weak, nonatomic) IBOutlet OutlinedLabel *rippleLabel;
@property (weak, nonatomic) IBOutlet UISwitch *rippleSwitch;
@property (nonatomic) JPSVolumeButtonHandler *volumeButtonHandler;
@property (nonatomic) WatchRemotePreview *watchRemotePreview;

- (void)snapStillImage;

@end

@implementation AVCamViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // setup openGL
    _rippleSwitch.on = YES;
    _rippleSwitch.hidden = YES;
    _rippleLabel.hidden = YES;
    EAGLContext* context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    [_glPreview setupGLWithContext:context];
    
    // openGL screen synchronization with displayLink
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:_glPreview selector:@selector(update)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    if (!context) {
        NSLog(@"Failed to create ES context");
    }
    
    // setup av
    self.avGenericController = [AVGenericController AVGenericControllerWithPreviewLayer:_previewView withPosition:AVCaptureDevicePositionBack completion:^(NSError *error) {
        if (!error){
            // device is setup let start the camera...
            [self start];
            [self addObservers];
            [self updateCameraInfo];
            // add volume handler;
            _volumeButtonHandler = [JPSVolumeButtonHandler volumeButtonHandlerWithUpBlock:^{
                [self snapStillImage];
            } downBlock:^{
                [self snapStillImage];
            }];
        }
    }];
    
    // add delegate to receive frames for opengl or applewatch
    
    _avGenericController.delegate = self;
    count = 0;
    
    // WatchConnectivity getSession
    if ([WCSession isSupported]) {
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
        self.watchRemotePreview = [[WatchRemotePreview alloc] init];
        _watchRemotePreview.isReady = YES;
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark -
#pragma mark ViewController orientation

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Note that the app delegate controls the device orientation notifications required to use the device orientation.
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if ( UIDeviceOrientationIsPortrait( deviceOrientation ) || UIDeviceOrientationIsLandscape( deviceOrientation ) ) {
        AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
        previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
    }
}
#pragma mark - Update View
-(void) updateCameraInfo{
    CMVideoFormatDescriptionRef desc = [_avGenericController.videoDevice.activeFormat formatDescription];
    CGSize size = CMVideoFormatDescriptionGetPresentationDimensions(desc,NO,NO);
    CMTime maxFrameRate = _avGenericController.videoDevice.activeVideoMaxFrameDuration;
    [_sizeButton setTitle:[NSString stringWithFormat:@"%ix%i",(int)size.width,(int)size.height] forState:UIControlStateNormal];
    [_frameRateButton setTitle:[NSString stringWithFormat:@"%ifps",maxFrameRate.timescale] forState:UIControlStateNormal];
    [_avGenericController.videoDevice lockForConfiguration:nil];
    
    // check if Torch
    //
    if ([_avGenericController.videoDevice hasTorch]){
        _flashLabel.hidden = NO;
        _flashSwitch.hidden = NO;
        _flashSwitch.on = _avGenericController.videoDevice.torchActive;
    }else{
        _flashLabel.hidden = YES;
        _flashSwitch.hidden = YES;
    }
    
    // check if HDR video available
    //
    if (_avGenericController.videoDevice.activeFormat.isVideoHDRSupported){
        _hdrLabel.hidden = NO;
        _hdrSwitch.hidden = NO;
        _hdrSwitch.on = _avGenericController.videoDevice.automaticallyAdjustsVideoHDREnabled ;
    }else{
        _hdrLabel.hidden = YES;
        _hdrSwitch.hidden = YES;
    }
    // check if Video Cinematic Stabilisation is available (appeared on iPhone 6 and iphone 6 plus)
    //
    if ([_avGenericController.videoDevice.activeFormat isVideoStabilizationModeSupported:AVCaptureVideoStabilizationModeCinematic]) {
        _isLabel.hidden = NO;
        _isSwitch.hidden = NO;
    }else{
        _isLabel.hidden = YES;
        _isSwitch.hidden = YES;
    }
    [_avGenericController.videoDevice unlockForConfiguration];
}
#pragma mark - KVO and Notifications

- (void)addObservers
{
    [self addObserver:self forKeyPath:@"avGenericController.videoDevice.lensPosition" options:NSKeyValueObservingOptionNew context:LensPositionContext];
    [self addObserver:self forKeyPath:@"avGenericController.videoDevice.exposureDuration" options:NSKeyValueObservingOptionNew context:ExposureDurationContext];
    [self addObserver:self forKeyPath:@"avGenericController.videoDevice.ISO" options:NSKeyValueObservingOptionNew context:ISOContext];
    [self addObserver:self forKeyPath:@"avGenericController.videoDevice.exposureTargetOffset" options:NSKeyValueObservingOptionNew context:ExposureTargetOffsetContext];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:_avGenericController.videoDevice];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:_avGenericController.captureSession];
    // A session can only run when the app is full screen. It will be interrupted in a multi-app layout, introduced in iOS 9,
    // see also the documentation of AVCaptureSessionInterruptionReason. Add observers to handle these session interruptions
    // and show a preview is paused message. See the documentation of AVCaptureSessionWasInterruptedNotification for other
    // interruption reasons.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:_avGenericController.captureSession];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:_avGenericController.captureSession];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserver:self forKeyPath:@"avGenericController.videoDevice.lensPosition" context:LensPositionContext];
    [self removeObserver:self forKeyPath:@"avGenericController.videoDevice.exposureDuration" context:ExposureDurationContext];
    [self removeObserver:self forKeyPath:@"avGenericController.videoDevice.ISO" context:ISOContext];
    [self removeObserver:self forKeyPath:@"avGenericController.videoDevice.exposureTargetOffset" context:ExposureTargetOffsetContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // id oldValue = change[NSKeyValueChangeOldKey];
    id newValue = change[NSKeyValueChangeNewKey];
    
    if ( context == LensPositionContext ) {
        if ( newValue && newValue != [NSNull null] ) {
            /* float newLensPosition = [newValue floatValue];
             if ( self.videoDevice.focusMode != AVCaptureFocusModeLocked ) {
             self.lensPositionSlider.value = newLensPosition;
             }
             self.lensPositionValueLabel.text = [NSString stringWithFormat:@"%.1f", newLensPosition];
             */
        }
    }
    else if ( context == ExposureDurationContext ) {
        if ( newValue && newValue != [NSNull null] ) {
            double newDurationSeconds = CMTimeGetSeconds( [newValue CMTimeValue] );
            if ( _avGenericController.videoDevice.exposureMode != AVCaptureExposureModeCustom ) {
                //double minDurationSeconds = MAX( CMTimeGetSeconds( self.videoDevice.activeFormat.minExposureDuration ), kExposureMinimumDuration );
                //double maxDurationSeconds = CMTimeGetSeconds( self.videoDevice.activeFormat.maxExposureDuration );
                // Map from duration to non-linear UI range 0-1
                //double p = ( newDurationSeconds - minDurationSeconds ) / ( maxDurationSeconds - minDurationSeconds ); // Scale to 0-1
                //self.exposureDurationSlider.value = pow( p, 1 / kExposureDurationPower ); // Apply inverse power
                
                if ( newDurationSeconds < 1 ) {
                    int digits = MAX( 0, 2 + floor( log10( newDurationSeconds ) ) );
                    self.exposureLabel.text = [NSString stringWithFormat:@"Exposure 1/%.*f", digits, 1/newDurationSeconds];
                }
                else {
                    self.exposureLabel.text = [NSString stringWithFormat:@"Exposure %.2f", newDurationSeconds];
                }
            }
        }
    }
    else if ( context == ISOContext ) {
        if ( newValue && newValue != [NSNull null] ) {
            float newISO = [newValue floatValue];
            
            if ( _avGenericController.videoDevice.exposureMode != AVCaptureExposureModeCustom ) {
                //self.ISOSlider.value = newISO;
            }
            self.isoLabel.text = [NSString stringWithFormat:@"ISO %i", (int)newISO];
        }
    }
    else if ( context == ExposureTargetOffsetContext ) {
        if ( newValue && newValue != [NSNull null] ) {
            // float newExposureTargetOffset = [newValue floatValue];
            // self.exposureTargetOffsetSlider.value = newExposureTargetOffset;
            // self.exposureTargetOffsetValueLabel.text = [NSString stringWithFormat:@"%.1f", newExposureTargetOffset];
        }
    }
    else {
        //[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
    //CGPoint devicePoint = CGPointMake( 0.5, 0.5 );
    //[self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

- (void)sessionRuntimeError:(NSNotification *)notification
{
    NSError *error = notification.userInfo[AVCaptureSessionErrorKey];
    NSLog( @"Capture session runtime error: %@", error );
    
    if ( error.code == AVErrorMediaServicesWereReset ) {
        dispatch_async( _avGenericController.sessionQueue, ^{
            // If we aren't trying to resume the session running, then try to restart it since it must have been stopped due to an error. See also -[resumeInterruptedSession:].
            /*  if ( self.isSessionRunning ) {
             [self.captureSession startRunning];
             self.sessionRunning = self.captureSession.isRunning;
             }
             else {
             dispatch_async( dispatch_get_main_queue(), ^{
             self.resumeButton.hidden = NO;
             } );
             }*/
        } );
    }
    else {
        //self.resumeButton.hidden = NO;
    }
}

- (void)sessionWasInterrupted:(NSNotification *)notification
{
    // In some scenarios we want to enable the user to resume the session running.
    // For example, if music playback is initiated via control center while using AVCamManual,
    // then the user can let the application resume the session running, which will stop music playback.
    // Note that stopping music playback in control center will not automatically resume the session running.
    // Also note that it is not always possible to resume, see -[resumeInterruptedSession:].
    
    // In iOS 9 and later, the userInfo dictionary contains information on why the session was interrupted.
    if (notification.userInfo){
        AVCaptureSessionInterruptionReason reason = [notification.userInfo[AVCaptureSessionInterruptionReasonKey] integerValue];
        NSLog( @"Capture session was interrupted with reason %ld", (long)reason );
        
        if ( reason == AVCaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient ||
            reason == AVCaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient ) {
            // Simply fade-in a button to enable the user to try to resume the session running.
            //self.resumeButton.hidden = NO;
            //self.resumeButton.alpha = 0.0;
            [UIView animateWithDuration:0.25 animations:^{
                //self.resumeButton.alpha = 1.0;
            }];
        }
        else if ( reason == AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps ) {
            // Simply fade-in a label to inform the user that the camera is unavailable.
            //self.cameraUnavailableLabel.hidden = NO;
            //self.cameraUnavailableLabel.alpha = 0.0;
            [UIView animateWithDuration:0.25 animations:^{
                //self.cameraUnavailableLabel.alpha = 1.0;
            }];
        }
    }
}

- (void)sessionInterruptionEnded:(NSNotification *)notification
{
    NSLog( @"Capture session interruption ended" );
    // do smart thing here ...
}

// switch between CALayer display (prefered for a classic preview) or OpenGL (if you want affect live stream)
- (IBAction)displayTypeAction:(UIButton*)sender {
    if (_glPreview.hidden){
        _glPreview.hidden = NO;
        _rippleLabel.hidden = NO;
        _rippleSwitch.hidden = NO;
        [sender setTitle:@"OpenGL" forState:UIControlStateNormal];
    }else{
        _glPreview.hidden = YES;
        _rippleLabel.hidden = YES;
        _rippleSwitch.hidden = YES;
        [sender setTitle:@"CALayer" forState:UIControlStateNormal];
    }
}
#pragma mark - Actions
- (IBAction)infoAction:(id)sender {
    _infoView.hidden = !_infoView.hidden;
}

// display a range a framerate for a given format

- (IBAction)frameRateAction:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Change Frame Rate"
                                                                   message:@""
                                                            preferredStyle:UIAlertControllerStyleActionSheet]; // 1
    __weak __typeof__(self) weakSelf = self;
    UIAlertAction *firstAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%i",(int)_avGenericController.currentSource.minFrameRate ]
                                                          style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                              if ( YES == [_avGenericController.videoDevice lockForConfiguration:NULL] )
                                                              {
                                                                  [_avGenericController.videoDevice setActiveVideoMinFrameDuration:CMTimeMake(1,_avGenericController.currentSource.minFrameRate)];
                                                                  [_avGenericController.videoDevice setActiveVideoMaxFrameDuration:CMTimeMake(1,_avGenericController.currentSource.minFrameRate)];
                                                                  [_avGenericController.videoDevice unlockForConfiguration];
                                                                  [weakSelf updateCameraInfo];
                                                              }
                                                              
                                                          }];
    
    [alert addAction:firstAction];
    static const CGFloat rates[13] = {5.,10.,15.,20.,24.,25.,30.,50.,60.,100.,120.,200.,240.};
    for (int i = 0; i < 13 ; i ++){
        if ((_avGenericController.currentSource.minFrameRate< rates[i])&&(_avGenericController.currentSource.maxFrameRate > rates[i])){
            UIAlertAction *middleAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%i",(int)rates[i] ]
                                                                   style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                       if ( YES == [_avGenericController.videoDevice lockForConfiguration:NULL] )
                                                                       {
                                                                           [_avGenericController.videoDevice setActiveVideoMinFrameDuration:CMTimeMake(1,rates[i])];
                                                                           [_avGenericController.videoDevice setActiveVideoMaxFrameDuration:CMTimeMake(1,rates[i])];
                                                                           [_avGenericController.videoDevice unlockForConfiguration];
                                                                           [weakSelf updateCameraInfo];
                                                                       }
                                                                       
                                                                   }];
            
            [alert addAction:middleAction];
        }
    }
    
    UIAlertAction *lasttAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%i",(int)_avGenericController.currentSource.maxFrameRate ]
                                                          style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                              if ( YES == [_avGenericController.videoDevice lockForConfiguration:NULL] )
                                                              {
                                                                  [_avGenericController.videoDevice setActiveVideoMinFrameDuration:CMTimeMake(1,_avGenericController.currentSource.maxFrameRate)];
                                                                  [_avGenericController.videoDevice setActiveVideoMaxFrameDuration:CMTimeMake(1,_avGenericController.currentSource.maxFrameRate)];
                                                                  [_avGenericController.videoDevice unlockForConfiguration];
                                                                  [weakSelf updateCameraInfo];
                                                              }
                                                              
                                                          }];
    
    [alert addAction:lasttAction];
    UIPopoverPresentationController *popPresenter = [alert
                                                     popoverPresentationController];
    popPresenter.sourceView = sender;
    popPresenter.sourceRect = sender.bounds;
    
    [self presentViewController:alert animated:YES completion:nil];
    [alert.view setTintColor:[UIColor blackColor]];
}

// Display all available size for a given device in order to select one.

- (IBAction)sizeAction:(UIButton* )sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Available capture formats"
                                                                   message:@""
                                                            preferredStyle:UIAlertControllerStyleActionSheet]; // 1
    __weak __typeof__(self) weakSelf = self;
    
    for (StreamSource *sourceVideo in _avGenericController.sources){
        if (sourceVideo.format == _avGenericController.videoDevice.activeFormat){
            UIAlertAction *firstAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"• %@", sourceVideo.name]
                                                                  style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                      
                                                                      
                                                                  }];
            
            [alert addAction:firstAction];
        }else{
            UIAlertAction *firstAction = [UIAlertAction actionWithTitle:sourceVideo.name
                                                                  style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                      if ( YES == [_avGenericController.videoDevice lockForConfiguration:NULL] )
                                                                      {
                                                                          _avGenericController.videoDevice.activeFormat = sourceVideo.format;
                                                                          [_avGenericController.videoDevice unlockForConfiguration];
                                                                          _avGenericController.currentSource = sourceVideo;
                                                                          [weakSelf updateCameraInfo];
                                                                      }
                                                                      
                                                                  }];
            
            [alert addAction:firstAction];
        }
        
    }
    UIPopoverPresentationController *popPresenter = [alert
                                                     popoverPresentationController];
    popPresenter.sourceView = sender;
    popPresenter.sourceRect = sender.bounds;
    [self presentViewController:alert animated:YES completion:nil];
    [alert.view setTintColor:[UIColor blackColor]];
}
//
- (IBAction)flashAction:(UISwitch*)sender {
    [_avGenericController.videoDevice lockForConfiguration:NULL];
    if (sender.on){
        [_avGenericController.videoDevice setTorchMode:AVCaptureTorchModeOn];
    }else{
        [_avGenericController.videoDevice setTorchMode:AVCaptureTorchModeOff];
    }
    [_avGenericController.videoDevice unlockForConfiguration];
    
}
// Video HDR
- (IBAction)hdrAction:(UISwitch*)sender {
    [_avGenericController.videoDevice lockForConfiguration:NULL];
    [_avGenericController.videoDevice setAutomaticallyAdjustsVideoHDREnabled:sender.on];
    [_avGenericController.videoDevice unlockForConfiguration];
}

// Image stabilization -
- (IBAction)isAction:(UISwitch*)sender {
    [_avGenericController.videoDevice lockForConfiguration:NULL];
    if (sender.on)
        [_avGenericController.videoConnection setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeCinematic  ];
    else
        
        [_avGenericController.videoConnection setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeOff  ];
    [_avGenericController.videoDevice unlockForConfiguration];
    
}
// OpenGL ripple effect-
- (IBAction)rippleAction:(UISwitch*)sender {
    _glPreview.simulation = sender.on;
    
}
-(IBAction)switchCameraTapped:(id)sender
{
    //Change camera source
    if(_avGenericController.captureSession)
    {
        [self removeObservers];
        //Remove existing input
        AVCaptureInput* currentCameraInput = _avGenericController.captureInput;
        if(((AVCaptureDeviceInput*)currentCameraInput).device.position == AVCaptureDevicePositionBack)
        {
            [_avGenericController setCameraWithPosition:AVCaptureDevicePositionFront];
        }
        else
        {
            [_avGenericController setCameraWithPosition:AVCaptureDevicePositionBack];
        }
        [self updateCameraInfo];
        [self addObservers];
    }
}

#pragma mark - AV Capture Session methods
- (AVCaptureSession*) session{
    return _avGenericController.captureSession;
}
- (void) start{
    [_avGenericController.captureSession startRunning];
}
- (void) stop{
    [_avGenericController.captureSession stopRunning];
}
#pragma mark -
#pragma mark AVCaptureSession delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    // glPreview deals with it
    [_glPreview captureOutput:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
    [_watchRemotePreview captureOutput:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
    
}

#pragma mark -  Capture still image method

- (void)snapStillImage
{
    dispatch_async( _avGenericController.sessionQueue, ^{
        AVCaptureConnection *stillImageConnection = [_avGenericController.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
        
        // Update the orientation on the still image output video connection before capturing.
        stillImageConnection.videoOrientation = previewLayer.connection.videoOrientation;
        
        // Capture a still image
        [_avGenericController.stillImageOutput captureStillImageAsynchronouslyFromConnection:[_avGenericController.stillImageOutput connectionWithMediaType:AVMediaTypeVideo] completionHandler:^( CMSampleBufferRef imageDataSampleBuffer, NSError *error ) {
            if ( error ) {
                NSLog( @"Error capture still image %@", error );
            }
            else if ( imageDataSampleBuffer ) {
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                //UIImage *image = [UIImage imageWithData:imageData];
                [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
                    if ( status == PHAuthorizationStatusAuthorized ) {
                        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                            [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto data:imageData options:nil];
                        } completionHandler:^( BOOL success, NSError *error ) {
                            if ( ! success ) {
                                NSLog( @"Error occured while saving image to photo library: %@", error );
                            }
                        }];
                    }
                }];
            }
        }];
    }
                   );
}

#pragma mark -
#pragma mark WatchConnectivity delegate
- (void)session:(WCSession *)session
didReceiveMessage:(NSDictionary<NSString *,
                   id> *)message
   replyHandler:(void (^)(NSDictionary<NSString *,
                          id> *replyMessage))replyHandler{
    
    NSLog(@"Watch %@",message);
    
    NSString* action = message[@"action"];
    if ([action isEqualToString:@"grab"]){
        [self snapStillImage];
        replyHandler(@{action:@"OK"});
    }else
        if ([action isEqualToString:@"switch"]){
            dispatch_async( dispatch_get_main_queue(), ^{
                
                [self switchCameraTapped:nil];
                replyHandler(@{action:@"OK"});
            });
        }
}

@end
