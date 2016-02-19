//
//  InterfaceController.m
//  AVCameExpert WatchKit App Extension
//
//  Created by Sébastien Luneau on 18/02/2016.
//  Copyright © 2016 Matchpix. All rights reserved.
//

@import WatchConnectivity;
#import "InterfaceController.h"


@interface InterfaceController()<WCSessionDelegate>
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *imageView;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *startLabel;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceGroup *mainGroup;

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
    if ([WCSession isSupported]) {
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
    }
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    [_startLabel setHidden:NO];
    [_mainGroup setHidden:YES];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    
    [_startLabel setHidden:NO];
    [_mainGroup setHidden:YES];
    [super didDeactivate];
}
- (IBAction)grabAction {
    if ([[WCSession defaultSession] isReachable]) {
    
    NSDictionary *applicationDict = @{@"action":@"grab"};
    [[WCSession defaultSession] sendMessage:applicationDict
                               replyHandler:^(NSDictionary *replyHandler) {
                                   
                               }
                               errorHandler:^(NSError *error) {
                                   
                               }
     ];
    }
}
- (void)session:(WCSession *)session didReceiveMessageData:(NSData *)messageData
   replyHandler:(void (^)(NSData *replyMessageData))replyHandler{
    
    [_startLabel setHidden:YES];
    [_mainGroup setHidden:NO];

    UIImage* image = [UIImage imageWithData:messageData];
    dispatch_async( dispatch_get_main_queue(), ^{
    [_imageView setImage:image];
    });
    //replyHandler([[NSData alloc] init]);
    
}
-(void)session:(WCSession *)session didReceiveMessageData:(NSData *)messageData{
    
    [_startLabel setHidden:YES];
    [_mainGroup setHidden:NO];

    UIImage* image = [UIImage imageWithData:messageData];
    dispatch_async( dispatch_get_main_queue(), ^{
        [_imageView setImage:image];
    });
}
- (IBAction)switchAction {
    if ([[WCSession defaultSession] isReachable]) {
        NSDictionary *applicationDict = @{@"action":@"switch"};
        [[WCSession defaultSession] sendMessage:applicationDict
                                   replyHandler:^(NSDictionary *replyHandler) {
                                       
                                   }
                                   errorHandler:^(NSError *error) {
                                       
                                   }
         ];

    }
}
@end



