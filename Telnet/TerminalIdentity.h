//
//  TerminalIdentity.h
//  xterminal
//
//  Created by Adam Eberbach on 10/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TelnetConstants.h"
#import "TelnetConnection.h"
#import "TerminalConstants.h"

@protocol TerminalResponderDelegate <NSObject>

typedef enum _TerminalResponseType {
    kResponseTerminalIdentity = 0
} TerminalResponseType;

- (void)sendResponse:(TerminalResponseType)response;

@end

@protocol TerminalDisplayDelegate <NSObject>

// display characters
- (void)fillScreenWithChar:(unsigned char)c;
- (void)characterDisplay:(unsigned char)c;
- (void)characterNonDisplay:(unsigned char)c;

// move cursor position
- (void)advanceRow;
- (void)decreaseRow;
- (void)cursorSetRow:(int)row column:(int)col;
- (void)cursorSetColumn:(int)col;
- (void)cursorLeft;
- (void)cursorUp;
- (void)cursorRight;
- (void)cursorDown;
- (void)setAutoWrapMode:(BOOL)wrap;

// clear
- (void)clearAll;
- (void)clearCursorLeft;
- (void)clearCursorRight;
- (void)clearRow;
- (void)clearCursorAbove;
- (void)clearCursorBelow;

// define and move terminal window
- (void)terminalWindowSetRowStart:(int)rowStart rowEnd:(int)rowEnd;
- (void)terminalWindowScrollUp;
- (void)terminalWindowScrollDown;

// display attributes
- (void)displayReset;
- (void)displaySetForegroundColor:(TerminalDisplayColor)color;
- (void)displaySetBackgroundColor:(TerminalDisplayColor)color;
- (void)displaySetTextBright:(BOOL)set;
- (void)displaySetTextDim:(BOOL)set;
- (void)displaySetTextUnderscore:(BOOL)set;
- (void)displaySetTextBlink:(BOOL)set;
- (void)displaySetTextReverse:(BOOL)set;
- (void)displaySetTextHidden:(BOOL)set;

@end

typedef enum _CommandState {
    kCommandStart,
    kCommandNumeric
} CommandState;

typedef enum _TelnetDataState {
    
    kTelnetDataStateRest = 0,
    kTelnetDataStateESC = 1,
    kTelnetDataStateCSI = 2
    
} TelnetDataState;

@interface TerminalIdentity : NSObject <TerminalIdentityDelegate> {
    
    id<TerminalDisplayDelegate>  __weak _displayDelegate;
    id<TerminalResponderDelegate> __weak _responderDelegate;
    
    NSMutableData *dataForDisplay;
}

@property id<TerminalDisplayDelegate>  __weak displayDelegate;
@property id<TerminalResponderDelegate>  __weak responderDelegate;

@end
