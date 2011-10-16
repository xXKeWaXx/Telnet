//
//  Glyph.m
//  TerminalAppView
//
//  Created by Adam Eberbach on 14/08/11.
//  Copyright (c) 2011 Adam Eberbach. All rights reserved.
//

#import "Glyph.h"

@implementation Glyph

+ (UIColor *)termBlackColor { return [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:1.f]; }
+ (UIColor *)termRedColor { return [UIColor colorWithRed:205.f/255.f green:0.f blue:0.f alpha:1.f]; }
+ (UIColor *)termGreenColor { return [UIColor colorWithRed:0.f green:205.f/255.f blue:0.f alpha:1.f]; }
+ (UIColor *)termYellowColor { return [UIColor colorWithRed:205.f/255.f green:205.f/255.f blue:0.f alpha:1.f]; }
+ (UIColor *)termBlueColor { return [UIColor colorWithRed:0.f green:0.f blue:238.f/255.f alpha:1.f]; }
+ (UIColor *)termMagentaColor { return [UIColor colorWithRed:205.f/255.f green:0.f blue:205.f/255.f alpha:1.f]; }
+ (UIColor *)termCyanColor { return [UIColor colorWithRed:0.f green:205.f/255.f blue:205.f/255.f alpha:1.f]; }
+ (UIColor *)termGrayColor { return [UIColor colorWithRed:229.f/255.f green:229.f/255.f blue:229.f/255.f alpha:1.f]; }

+ (UIColor *)UIColorWithGlyphColor:(GlyphColor)glyphColor {
    
    UIColor *bgColor;
    switch(glyphColor) {
        case kGlyphColorRed:
            bgColor = [Glyph termRedColor];
            break;
        case kGlyphColorGreen:
            bgColor = [Glyph termGreenColor];
            break;
        case kGlyphColorYellow:
            bgColor = [Glyph termYellowColor];
            break;
        case kGlyphColorBlue:
            bgColor = [Glyph termBlueColor];
            break;
        case kGlyphColorMagenta:
            bgColor = [Glyph termMagentaColor];
            break;
        case kGlyphColorCyan:
            bgColor = [Glyph termCyanColor];
            break;
        case kGlyphColorGray:
            bgColor = [Glyph termGrayColor];
            break;
        case kGlyphColorBlack:
        default:
            break;
    }
    return bgColor;
}

// set glyph to the current erase state, with no text set
- (void)eraseWithBG:(GlyphColor)background {
    
    self.backgroundColor = [Glyph UIColorWithGlyphColor:background];
    self.text = nil;
}

- (void)drawRect:(CGRect)rect {
    
    // turn off antialiasing for nice sharp terminal glyphs
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextSetAllowsAntialiasing(context, NO);
    [super drawRect:rect];
    CGContextRestoreGState(context);
}

@end
