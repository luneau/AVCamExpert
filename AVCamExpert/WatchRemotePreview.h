//
//  WatchRemotePreview.h
//  AVCamExpert
//
//  Created by Sébastien Luneau on 18/02/2016.
//  Copyright © 2016 Matchpix. All rights reserved.
//


@import UIKit;
@import AVFoundation;
@import WatchConnectivity;

@interface WatchRemotePreview : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate,WCSessionDelegate>
@property (nonatomic) BOOL isReady;
@property (nonatomic) NSDate *lastFrameDate;
@end
