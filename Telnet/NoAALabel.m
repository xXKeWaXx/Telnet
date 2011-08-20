//
//  NoAALabel.m
//  TerminalAppView
//
//  Created by Adam Eberbach on 14/08/11.
//  Copyright (c) 2011 Adam Eberbach. All rights reserved.
//

#import "NoAALabel.h"

@implementation NoAALabel

- (void)drawRect:(CGRect)rect {
    
    // turn off antialiasing for nice sharp terminal glyphs
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextSetAllowsAntialiasing(context, NO);
    [super drawRect:rect];
    CGContextRestoreGState(context);
}

@end
