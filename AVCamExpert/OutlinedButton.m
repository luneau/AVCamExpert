//
//  OutlinedButton.m
//  AVCamExpert
//
//  Created by Sébastien Luneau on 01/12/2015.
//  Copyright © 2015 Matchpix. All rights reserved.
//

#import "OutlinedButton.h"

@implementation OutlinedButton
-(id) init{
    self = [super init];
    if (self){
        self.titleLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:self.titleLabel.font.pointSize];
        self.layer.borderWidth = 1.5;
        self.layer.cornerRadius = self.bounds.size.height/2.;
        self.layer.borderColor = [UIColor whiteColor].CGColor;
        
    }
    return self;
}
-(id) initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self){
        self.titleLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:self.titleLabel.font.pointSize];
        self.layer.borderWidth = 1.5;
        self.layer.cornerRadius = self.bounds.size.height/2.;
        self.layer.borderColor = [UIColor whiteColor].CGColor;
        
    }
    return self;
}
@end
