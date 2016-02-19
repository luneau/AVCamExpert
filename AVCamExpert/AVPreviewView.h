//
//  PreviewView.h
//  AVCamExpert
//
//  Created by Sébastien Luneau on 01/12/2015.
//  Copyright © 2015 Matchpix. All rights reserved.
//

@import UIKit;

@class AVCaptureSession;
@class StreamSource;

@interface AVPreviewView : UIView

@property (nonatomic) AVCaptureSession *session;

@end
