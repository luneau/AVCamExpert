//
//  StreamSource.h
//  AVCamExpert
//
//  Created by Sébastien Luneau on 01/12/2015.
//  Copyright © 2015 Matchpix. All rights reserved.
//

@import Foundation;
@import AVFoundation;

@interface StreamSource : NSObject
@property (nonatomic,strong) NSString* name;
@property (nonatomic,assign) CGSize size;
@property (nonatomic,strong) AVCaptureDeviceFormat* format;
@property (assign, nonatomic) Float64 minFrameRate;
@property (assign, nonatomic) Float64 maxFrameRate;

+ (NSArray<StreamSource*>*) availableSources:(AVCaptureDevice*) videoDevice;

@end
