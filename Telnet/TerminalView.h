//
//  TerminalView.h
//  TerminalAppView
//
//  Created by Adam Eberbach on 14/08/11.
//  Copyright (c) 2011 Adam Eberbach. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TelnetConnection.h"

#define kTerminalRows (24)
#define kTerminalColumns (80)

#define kGlyphFontSize (15.f)
#define kGlyphWidth (9.f)
#define kGlyphHeight (18.f)

#define kNVTSpecialCharNUL  (0)
#define kNVTSpecialCharLF   (10)
#define kNVTSpecialCharCR   (13)

// VT100 text attributes
 
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
    
    int cursorRow;
    int cursorColumn;

    UILabel *cursor;
    
    NSMutableArray *terminalRows;
    
    // blink and underscore are done by manipulating the view not the font
    NSMutableArray *underlinedGlyphs;
    NSMutableArray *blinkingGlyphs;
    
    NSMutableData *dataForDisplay;
    
}

@end
