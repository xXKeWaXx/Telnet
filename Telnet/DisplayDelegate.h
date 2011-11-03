//
//  DisplayDelegate.h
//  xterminal
//
//  Created by Adam Eberbach on 13/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef uint16_t glyphAttributes;

#define kModeIntensity  (0x0001)
#define kModeInverse    (0x0002)
#define kModeBold       (0x0004)
#define kModeUnderline  (0x0008)
#define kModeBlink      (0x0010)

typedef enum _color {
    kGlyphColorDefault,
    kGlyphColorBlack,
    kGlyphColorRed,
    kGlyphColorGreen,
    kGlyphColorYellow,
    kGlyphColorBlue,
    kGlyphColorMagenta,
    kGlyphColorCyan,
    kGlyphColorGray
    
} GlyphColor;

@protocol DisplayDelegate <NSObject>
- (void)resetScreenWithRows:(int)rows andColumns:(int)cols;
- (void)displayChar:(uint8_t)c atRow:(int)row atColumn:(int)col;
- (void)setAttributes:(uint16_t)attributes foreground:(GlyphColor)fg background:(GlyphColor)bg;
- (void)scrollUpRegionTop:(int)top regionSpan:(int)rows;
- (void)setColumns:(int)cols;

@end
