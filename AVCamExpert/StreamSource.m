//
//  StreamSource.m
//  AVCamExpert
//
//  Created by Sébastien Luneau on 01/12/2015.
//  Copyright © 2015 Matchpix. All rights reserved.
//

#import "StreamSource.h"
/*@interface StreamSource ()
 {
 AVCaptureSession * session;
 NSArray * captureDevices;
 AVCaptureDeviceInput * captureInput;
 AVCaptureVideoDataOutput * captureOutput;
 int currentCameraIndex;
 }
 @end*/
@implementation StreamSource

+ (NSArray<StreamSource*>*) availableSources:(AVCaptureDevice*) videoDevice{
    NSMutableArray <StreamSource*>* sources = [NSMutableArray array];
    
    int idx=0;
    for (AVCaptureDeviceFormat* currdf in videoDevice.formats){
        StreamSource *aSource = [[StreamSource alloc] init];
        CMVideoFormatDescriptionRef desc = [currdf formatDescription];
        if (CMFormatDescriptionGetMediaSubType(desc)=='420f'){
            NSArray *videoSupportedFrameRateRanges = [currdf videoSupportedFrameRateRanges];
            AVFrameRateRange * fps = videoSupportedFrameRateRanges[0];
            aSource.size = CMVideoFormatDescriptionGetPresentationDimensions(desc,NO,NO);
            aSource.minFrameRate = [fps minFrameRate];
            aSource.maxFrameRate = [fps maxFrameRate];
            aSource.name =  [NSString stringWithFormat:@"%ix%i {%i-%ifps}",(int)aSource.size.width,(int)aSource.size.height,(int)[fps minFrameRate],(int)[fps maxFrameRate]];
            aSource.format = currdf;
            if (currdf.isVideoHDRSupported){
                aSource.name = [NSString stringWithFormat:@"%@ - HDR",aSource.name];
            }
            if ([currdf isVideoStabilizationModeSupported:AVCaptureVideoStabilizationModeCinematic]) {
                
                aSource.name = [NSString stringWithFormat:@"%@ - Cine. Stab.",aSource.name];
            }
            NSLog(@"%@ - %i", currdf, idx++);
            [sources addObject:aSource];
        }
    }
    
    
    return [NSArray arrayWithArray:sources] ;
}

@end
