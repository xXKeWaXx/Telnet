//
//  TerminalView.h
//  TerminalAppView
//
//  Created by Adam Eberbach on 14/08/11.
//  Copyright (c) 2011 Adam Eberbach. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TelnetConnection.h"

@class NoAALabel;

#define kTerminalRows (24)
#define kTerminalColumns (80)

#define kGlyphFontSize (15.f)
#define kGlyphWidth (9.f)
#define kGlyphHeight (18.f)

#define kNVTSpecialCharNUL  (0)
#define kNVTSpecialCharLF   (10)
#define kNVTSpecialCharCR   (13)

// VT100 text attributes

typedef enum _TextAttributes {
    
    kTextAtributeClear = 0,
    kTextAttributeBright = 1,
    kTextAttributeDim = 2,
    kTextAttributeUnderscore = 4,
    kTextAttributeBlink = 5,
    kTextAttributeReverse = 7,
    kTextAttributeHidden = 8    
    
} TextAttributes;

// 0	Reset all attributes
// 1	Bright
// 2	Dim
// 4	Underscore	
// 5	Blink
// 7	Reverse
// 8	Hidden

// Foreground Colours
// 30	Black
// 31	Red
// 32	Green
// 33	Yellow
// 34	Blue
// 35	Magenta
// 36	Cyan
// 37	White

// Background Colours
// 40	Black
// 41	Red
// 42	Green
// 43	Yellow
// 44	Blue
// 45	Magenta
// 46	Cyan
// 47	White
 
@interface TerminalView : UIView <TerminalConnectionDisplayDelegate> {
    
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

    NoAALabel *cursor;
    
    NSMutableArray *terminalRows;
    
    // blink and underscore are done by manipulating the view not the font
    NSMutableArray *underlinedGlyphs;
    NSMutableArray *blinkingGlyphs;
    
    NSMutableData *dataForDisplay;
    
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
