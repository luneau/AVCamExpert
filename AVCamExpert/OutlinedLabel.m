//
//  OutlinedLabel
//  AVCamExpert
//
//  Created by Sébastien Luneau on 01/12/2015.
//  Copyright © 2015 Matchpix. All rights reserved.
//

#import "OutlinedLabel.h"

@implementation OutlinedLabel

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (void)drawTextInRect:(CGRect)rect {
    
    CGSize shadowOffset = self.shadowOffset;
    UIColor *textColor = self.textColor;
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(c, 1);
    CGContextSetLineJoin(c, kCGLineJoinRound);
    
    CGContextSetTextDrawingMode(c, kCGTextStroke);
    self.textColor = [UIColor blackColor];
    [super drawTextInRect:rect];
    
    CGContextSetTextDrawingMode(c, kCGTextFill);
    self.textColor = textColor;
    self.shadowOffset = CGSizeMake(0, 0);
    [super drawTextInRect:rect];
    
    self.shadowOffset = shadowOffset;
    
    /*CGContextSetLineWidth(c, 1+2);
    CGContextSetLineJoin(c, kCGLineJoinRound);
    CGContextSetLineCap(c, kCGLineCapRound);
    //Set the width of the pen mark
    
    CGContextSetStrokeColorWithColor(c, [UIColor blackColor].CGColor);
    // Draw a line
    //Start at this point
    CGContextMoveToPoint(c, (self.bounds.size.width-self.font.pointSize)/2, (self.bounds.size.height-self.font.pointSize)/2.f+ 0.0);
    
    //Give instructions to the CGContext
    //(move "pen" around the screen)
    CGContextAddLineToPoint(c, (self.bounds.size.width+self.font.pointSize)/2, (self.bounds.size.height-self.font.pointSize)/2.f+self.font.pointSize);
    //Draw it
    CGContextStrokePath(c);
    
    CGContextSetStrokeColorWithColor(c, self.textColor.CGColor);
    
    CGContextSetLineWidth(c, 1);
    CGContextSetLineJoin(c, kCGLineJoinRound);
    CGContextSetLineCap(c, kCGLineCapRound);
    //Set the width of the pen mark
    
    // Draw a line
    //Start at this point
    CGContextMoveToPoint(c, (self.bounds.size.width-self.font.pointSize)/2, (self.bounds.size.height-self.font.pointSize)/2.f+ 0.0);
    
    //Give instructions to the CGContext
    //(move "pen" around the screen)
    CGContextAddLineToPoint(c, (self.bounds.size.width+self.font.pointSize)/2, (self.bounds.size.height-self.font.pointSize)/2.f+self.font.pointSize);
    //Draw it
    CGContextStrokePath(c);*/
    
}
@end
