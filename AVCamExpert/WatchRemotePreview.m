//
//  WatchRemotePreview.m
//  AVCamExpert
//
//  Created by Sébastien Luneau on 18/02/2016.
//  Copyright © 2016 Matchpix. All rights reserved.
//

#import "WatchRemotePreview.h"


#define FRAME_INTERVAL 1./5.

@implementation WatchRemotePreview
#pragma mark -
#pragma mark AVCaptureSession delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    if ([[WCSession defaultSession] isReachable]) {
        
        NSDate * curDate = [NSDate date];
        if ((curDate.timeIntervalSince1970 - _lastFrameDate.timeIntervalSince1970)>FRAME_INTERVAL){
            _lastFrameDate = curDate;
            CVImageBufferRef cvImage = CMSampleBufferGetImageBuffer(sampleBuffer);
            CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:cvImage];
            UIImage* image = [UIImage imageWithCIImage:ciImage];
            
            CGSize newSize = CGSizeMake(64, image.size.height*64./image.size.width);
            UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
            [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
            UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            // need to fix bad orientation
            
            switch (connection.videoOrientation) {
                case AVCaptureVideoOrientationPortrait:
                    newImage = [UIImage imageWithCGImage:newImage.CGImage scale:1. orientation:UIImageOrientationUp];
                    break;
                case AVCaptureVideoOrientationPortraitUpsideDown:
                    newImage = [UIImage imageWithCGImage:newImage.CGImage scale:1. orientation:UIImageOrientationDown];
                    break;
                case AVCaptureVideoOrientationLandscapeRight:
                    newImage = [UIImage imageWithCGImage:newImage.CGImage scale:1. orientation:UIImageOrientationLeft];
                    break;
                case AVCaptureVideoOrientationLandscapeLeft:
                    newImage = [UIImage imageWithCGImage:newImage.CGImage scale:1. orientation:UIImageOrientationRight];
                    break;
                    
                default:
                    break;
            }
            NSData *data = UIImageJPEGRepresentation(newImage, 0.4);
            
            [[WCSession defaultSession] sendMessageData:data replyHandler:nil errorHandler:nil];
            
        }
        
    }
    
}
@end
