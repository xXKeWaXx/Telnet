//
//  TerminalView.h
//  TerminalAppView
//
//  Created by Adam Eberbach on 14/08/11.
//  Copyright (c) 2011 Adam Eberbach. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TelnetConnection.h"
#import "TerminalIdentity.h"

@class NoAALabel;

#define kTerminalRows (24)
#define kTerminalColumns (80)

#define kGlyphFontSize (15.f)
#define kGlyphWidth (9.f)
#define kGlyphHeight (18.f)

// VT100 text attributes

@interface TerminalView : UIView <TerminalDisplayDelegate> {
    
    NSDictionary *commandSequenceHandlerDictionary;
    
    // DEC window gives start and end row, e.g. ESC[1;24r = rows 1 to 24 are the current window.
    int windowBegins;
    int windowEnds;
    
    BOOL textIsBright;
    BOOL textIsDim;
    BOOL textIsUnderscore;
    BOOL textIsBlink;
    BOOL textIsReverse;
    BOOL textIsHidden;

    NSMutableArray *tabStops;
    
    UIColor *foregroundColor;
    UIColor *backgroundColor;

    int terminalRow;
    int terminalColumn;
    
    NoAALabel *cursor;
    
    NSMutableArray *terminalRows;
    
    // blink and underscore are done by manipulating the view not the font
    NSMutableArray *underlinedGlyphs;
    NSMutableArray *blinkingGlyphs;
    
}

@property BOOL textIsBright;
@property BOOL textIsDim;
@property BOOL textIsUnderscore;
@property BOOL textIsBlink;
@property BOOL textIsReverse;
@property BOOL textIsHidden;

@property int windowBegins;
@property int windowEnds;
@property (nonatomic, retain) NoAALabel *cursor;
@property (nonatomic, retain) NSMutableArray *terminalRows;

@end
