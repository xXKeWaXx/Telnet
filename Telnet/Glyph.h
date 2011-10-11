//
//  Glyph.h
//  TerminalAppView
//
//  Created by Adam Eberbach on 14/08/11.
//  Copyright (c) 2011 Adam Eberbach. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kGlyphFontSize (15.f)
#define kGlyphWidth (9.f)
#define kGlyphHeight (18.f)

typedef enum _intensity {
   
    kIntensityNormal,
    kIntensityDim,
    kIntensityBright
    
} GlyphIntensity;

typedef enum _color {

    kGlyphColorBlack,
    kGlyphColorRed,
    kGlyphColorGreen,
    kGlyphColorYellow,
    kGlyphColorBlue,
    kGlyphColorMagenta,
    kGlyphColorCyan,
    kGlyphColorWhite
    
} GlyphColor;

@interface Glyph : UILabel {

    GlyphColor color;
    GlyphIntensity intensity;
    int row;
    int column;
    
}

- (void)erase;

@end
