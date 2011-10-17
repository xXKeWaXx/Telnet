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
+ (UIColor *)termDarkGrayColor { return [UIColor colorWithRed:127.f/255.f green:127.f/255.f blue:127.f/255.f alpha:1.f]; }

+ (UIColor *)termRedColor { return [UIColor colorWithRed:205.f/255.f green:0.f blue:0.f alpha:1.f]; }
+ (UIColor *)termIntenseRedColor { return [UIColor colorWithRed:1.f green:0.f blue:0.f alpha:1.f]; }

+ (UIColor *)termGreenColor { return [UIColor colorWithRed:0.f green:205.f/255.f blue:0.f alpha:1.f]; }
+ (UIColor *)termIntenseGreenColor { return [UIColor colorWithRed:0.f green:1.f blue:0.f alpha:1.f]; }

+ (UIColor *)termYellowColor { return [UIColor colorWithRed:205.f/255.f green:205.f/255.f blue:0.f alpha:1.f]; }
+ (UIColor *)termIntenseYellowColor { return [UIColor colorWithRed:1.f green:1.f blue:0.f alpha:1.f]; }

+ (UIColor *)termBlueColor { return [UIColor colorWithRed:0.f green:0.f blue:238.f/255.f alpha:1.f]; }
+ (UIColor *)termIntenseBlueColor { return [UIColor colorWithRed:92.f/255.f green:92.f/255.f blue:255.f/255.f alpha:1.f]; }

+ (UIColor *)termMagentaColor { return [UIColor colorWithRed:205.f/255.f green:0.f blue:205.f/255.f alpha:1.f]; }
+ (UIColor *)termIntenseMagentaColor { return [UIColor colorWithRed:255.f/255.f green:0.f blue:255.f/255.f alpha:1.f]; }

+ (UIColor *)termCyanColor { return [UIColor colorWithRed:0.f green:205.f/255.f blue:205.f/255.f alpha:1.f]; }
+ (UIColor *)termIntenseCyanColor { return [UIColor colorWithRed:0.f green:1.f blue:1.f alpha:1.f]; }

+ (UIColor *)termGrayColor { return [UIColor colorWithRed:229.f/255.f green:229.f/255.f blue:229.f/255.f alpha:1.f]; }
+ (UIColor *)termWhiteColor { return [UIColor colorWithRed:1.f green:1.f blue:1.f alpha:1.f]; }

+ (UIColor *)UIColorWithGlyphColor:(GlyphColor)glyphColor intensity:(BOOL)intense {
    
    UIColor *bgColor;
    switch(glyphColor) {
        case kGlyphColorRed:
            if(intense == NO)
                bgColor = [Glyph termRedColor];
            else
                bgColor = [Glyph termIntenseRedColor];
            break;
        case kGlyphColorGreen:
            if(intense == NO)
                bgColor = [Glyph termGreenColor];
            else
                bgColor = [Glyph termIntenseGreenColor];
            break;
        case kGlyphColorYellow:
            if(intense == NO)
                bgColor = [Glyph termYellowColor];
            else
                bgColor = [Glyph termIntenseYellowColor];
            break;
        case kGlyphColorBlue:
            if(intense == NO)
                bgColor = [Glyph termBlueColor];
            else
                bgColor = [Glyph termIntenseBlueColor];
            break;
        case kGlyphColorMagenta:
            if(intense == NO)
                bgColor = [Glyph termMagentaColor];
            else
                bgColor = [Glyph termIntenseMagentaColor];
            break;
        case kGlyphColorCyan:
            if(intense == NO)
                bgColor = [Glyph termCyanColor];
            else
                bgColor = [Glyph termIntenseCyanColor];
            break;
        case kGlyphColorGray:
            if(intense == NO)
                bgColor = [Glyph termGrayColor];
            else
                bgColor = [Glyph termWhiteColor];
            break;
        case kGlyphColorBlack:
        default:
            if(intense == NO)
                bgColor = [Glyph termBlackColor];
            else
                bgColor = [Glyph termDarkGrayColor];
            break;
    }
    return bgColor;
}

// set glyph to the current erase state, with no text set
- (void)eraseWithBG:(GlyphColor)background {
    
    self.backgroundColor = [Glyph UIColorWithGlyphColor:background intensity:NO];
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
