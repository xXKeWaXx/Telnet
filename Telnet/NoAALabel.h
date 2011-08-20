//
//  NoAALabel.h
//  TerminalAppView
//
//  Created by Adam Eberbach on 14/08/11.
//  Copyright (c) 2011 Adam Eberbach. All rights reserved.
//

#import <UIKit/UIKit.h>

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

@interface NoAALabel : UILabel {

    GlyphColor color;
    GlyphIntensity intensity;
    
}

@end
