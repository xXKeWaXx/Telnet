//
//  Glyph.h
//  TerminalAppView
//
//  Created by Adam Eberbach on 14/08/11.
//  Copyright (c) 2011 Adam Eberbach. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DisplayDelegate.h"

#define kGlyphFontSize (15.f)
#define kGlyphWidth (9.f)
#define kGlyphHeight (18.f)

typedef enum _intensity {
   
    kIntensityNormal,
    kIntensityDim,
    kIntensityBright
    
} GlyphIntensity;

@interface Glyph : UILabel {

    GlyphColor color;
    GlyphIntensity intensity;
    UIColor *foregroundColor;
//    UIColor *bgColor;
    int row;
    int column;
    BOOL isUnderlined;
    
}

- (void)eraseWithBG:(GlyphColor)background;

+ (UIColor *)termBlackColor;
+ (UIColor *)termDarkGrayColor;
+ (UIColor *)termRedColor;
+ (UIColor *)termIntenseRedColor;
+ (UIColor *)termGreenColor;
+ (UIColor *)termIntenseGreenColor;
+ (UIColor *)termYellowColor;
+ (UIColor *)termIntenseYellowColor;
+ (UIColor *)termBlueColor;
+ (UIColor *)termIntenseBlueColor;
+ (UIColor *)termMagentaColor;
+ (UIColor *)termIntenseMagentaColor;
+ (UIColor *)termCyanColor;
+ (UIColor *)termIntenseCyanColor;
+ (UIColor *)termGrayColor;
+ (UIColor *)termWhiteColor;

+ (UIColor *)UIColorWithGlyphColor:(GlyphColor)glyphColor intensity:(BOOL)intense;

- (void)toggleBlink:(BOOL)blink;

@property BOOL isUnderlined;

@end
