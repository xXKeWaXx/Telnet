//
//  Display.h
//  xterminal
//
//  Created by Adam Eberbach on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Terminal.h"
#import "Glyph.h"

@interface Display : UIView <DisplayDelegate> {

    // array of arrays containing glyphs; screen memory
    NSMutableArray *terminalRows;
    int terminalColumns;
    
    UIFont *normalFont;
    UIFont *boldFont;
    
    uint16_t currentAttributes;
    GlyphColor defaultBackgroundColor;
    GlyphColor defaultForegroundColor;
    GlyphColor backgroundColor;
    GlyphColor foregroundColor;
    
    NSTimer *blinkTimer;
    NSMutableArray *blinkArray;
}

+ (CGSize)sizeForRows:(int)rows andColumns:(int)cols;

- (CGFloat)glyphHeight;
- (CGFloat)glyphWidth;

@end
