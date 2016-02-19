//
//  CALayerPreviewView.m
//  AVCamExpert
//
//  Created by Sébastien Luneau on 01/12/2015.
//  Copyright © 2015 Matchpix. All rights reserved.
//

@import AVFoundation;
#import "CALayerPreviewView.h"
#import "StreamSource.h"

@implementation CALayerPreviewView
+ (Class)layerClass
{
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session
{
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
    return previewLayer.session;
}

- (void)setSession:(AVCaptureSession *)session
{
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
    previewLayer.session = session;
    super.session = session;
}

@end
