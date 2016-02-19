//
//  GLPreviewView.h
//  AVCamExpert
//
//  Created by Sébastien Luneau on 01/12/2015.
//  Copyright © 2016 Matchpix. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>

@interface GLPreviewView : GLKView <GLKViewDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic) BOOL simulation;
- (void)setupGLWithContext:(EAGLContext*)context;
- (void)tearDownGL;
- (void)cleanUpTextures;
- (void)update;
@end
