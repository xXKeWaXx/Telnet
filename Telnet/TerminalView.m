//
//  TerminalView.m
//  TerminalAppView
//
//  Created by Adam Eberbach on 14/08/11.
//  Copyright (c) 2011 Adam Eberbach. All rights reserved.
//

#import "TerminalView.h"
#import "NoAALabel.h"

@implementation TerminalView

- (void)scrollUp {

    static int scrolledUp = 0;
    
    NSLog(@"Scrolled up %d times", scrolledUp++);
    
    NSMutableArray *topLine = [terminalRows objectAtIndex:0];
    [terminalRows removeObjectAtIndex:0];

    // alter top line to become bottom line, text is cleared and frame.origin.y set
    CGRect glyphFrame;
    CGFloat rowYOrigin = kGlyphHeight * (kTerminalRows - 1);
    for(UILabel* glyph in topLine) {
        glyph.text = nil;
        glyphFrame = glyph.frame;
        glyphFrame.origin.y = rowYOrigin;
        glyph.frame = glyphFrame;
    }
    // alter frame of all other lines so that they move up one line
    rowYOrigin = 0.f;
    for(NSMutableArray *array in terminalRows) {
        for(UILabel* glyph in array) {
            glyphFrame = glyph.frame;
            glyphFrame.origin.y = rowYOrigin;
            glyph.frame = glyphFrame;
        }
        rowYOrigin += kGlyphHeight;
    }
    // add the bottom line
    [terminalRows addObject:topLine];
}

- (void)cursorMoveToRow:(int)toRow toCol:(int)toCol {
    
    cursor.backgroundColor = [UIColor blackColor];
    cursor = [[terminalRows objectAtIndex:toRow] objectAtIndex:toCol];
    cursor.backgroundColor = [UIColor grayColor];
}

- (void)incrementCursorRow {

    if(cursorRow < kTerminalRows - 1) {
        cursorRow++;
    } 
    else {
       [self scrollUp];
    }
    [self cursorMoveToRow:cursorRow toCol:cursorColumn];
}

- (void)incrementCursorColumn {
    
    if(cursorColumn < kTerminalColumns - 1) {
        cursorColumn++;
        [self cursorMoveToRow:cursorRow toCol:cursorColumn];
    }
}

typedef enum _TelnetDataState {

    kTelnetDataStateRest = 0,
    kTelnetDataStateESC = 1,
    kTelnetDataStateCSI = 2
    
} TelnetDataState;

- (void)processCommandSequence:(NSData *)command {
    
    unsigned char * c = (unsigned char *)[command bytes];
    int len = [command length];
    
    NSString *commandDebugString = [NSString string];

    while(len--) {
        unsigned char d = *c++;
        if(d == 033)
            commandDebugString = [commandDebugString stringByAppendingFormat:@"ESC "];
        else
            commandDebugString = [commandDebugString stringByAppendingFormat:@"%c", d];
    }    
    NSLog(@"command: %@", commandDebugString);
    
    
}

- (void)processDataChunk {
    
    unsigned char *c = (unsigned char *)[dataForDisplay bytes];
    int len = [dataForDisplay length];
    TelnetDataState dataState = kTelnetDataStateRest;
    
    NSMutableData *command = [NSMutableData data];
    BOOL continuing = YES;
    
    while(len-- && continuing) {
        
        unsigned char d = *c++;
        
        switch(dataState) {
                
            case kTelnetDataStateRest: {

                // simplest case - not part of a command sequence, output a glyph
                if(d >= 32 && d <= 126) {
                    
                    UILabel *glyph = [[terminalRows objectAtIndex:cursorRow] objectAtIndex:cursorColumn];
                    glyph.text = [NSString stringWithFormat:@"%c", d];
                    [self incrementCursorColumn];
//                    continuing = NO;
                    break;
                    
                // individual special characters
                } else if (d == 000) { // NUL (ignored)
                } else if (d == 005) { // ENQ transmit answerback
                } else if (d == 007) { // BEL bell sound
                } else if (d == 010) { // BS backspace
                } else if (d == 011) { // HT next horizontal tab stop or right margin if no more stops exist
                } else if (d == 012 || d == 013 || d == 014) { // LF, VT, FF line feed
                    [self incrementCursorRow];
                    continuing = NO;
                } else if (d == 015) { // CR carriage return
                    cursorColumn = 0;
                    [self cursorMoveToRow:cursorRow toCol:cursorColumn];
                    continuing = NO;
                } else if (d == 016) { // SQ invoke G1 character set
                } else if (d == 017) { // SI invoke G0 character set
                } else if (d == 021) { // XON resume transmission
                } else if (d == 023) { // XOFF pause transmission                    
                } else if (d == 033) { // ESC initiate control sequence
                    [command appendBytes:&d length:1];
                    dataState = kTelnetDataStateESC;
                } else if (d == 0177) { // ignored
                }
            }
            break;
                
            case kTelnetDataStateESC: {
                
                if (d == 0133) { // [ - enter CSI state
                    [command appendBytes:&d length:1];
                    dataState = kTelnetDataStateCSI;
                } else if (d == 033) { // ESC - discard all preceding control sequence construction, begin again
                    command = [NSMutableData dataWithBytes:&d length:1];
                } else if (d == 0104 || d == 0105 || d == 0115) { // D index, E newline, M reverse index
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0101 || d == 0102 || d == 060 || d == 061 || d == 062) { // A UK, B USASCII, 0 Special graphics, 1 alt ROM, 2 alt ROM special graphics
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                    
                } else if (d == 067 || d == 070) { // 7 save cursor, 8 restore cursor
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 030 || d == 032) { // CAN, SUB cancel current control sequence
                    command = nil;
                    continuing = NO;
                } else if (d == 050 || d == 051) { // ( G0 designator, ) G1 designator
                    [command appendBytes:&d length:1];
                } else {
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                }
            }
            break;

            case kTelnetDataStateCSI: {
                
                if (d == 033) { // ESC - discard all preceding control sequence construction, begin again
                    command = [NSMutableData dataWithBytes:&d length:1];
                } else if (d >= 060 && d <= 071) { // could be a digit giving a count for the command
                    [command appendBytes:&d length:1];
                } else if (d == 0101 || d == 0102 || d == 0103 || d == 0104) { // A up, B down, C left, D right
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0154) { // l selectable modes
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0161) { // q load LEDs
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0170) { // x report terminal parameters
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0146) { // f horizontal and vertical position
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0162) { // r set top and bottom margins
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0057) { // / reset mode
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0150) { // h set mode
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0156) { // n status report
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0143) { // c what are you?
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0155) { // m set character attributes
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 073) { // ; - a compound command
                    [command appendBytes:&d length:1];
                } else if (d == 0112 || d == 0113) { // J line erase, K screen erase
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                }
            }
            break;

        }
    }
    
    if(len > 0) {
        
        dataForDisplay = [NSMutableData dataWithBytes:c length:len];
        
        // more data to display, allow run loop to continue and return here
        [self performSelector:@selector(processDataChunk) withObject:nil afterDelay:0.0f];
    } else {
        dataForDisplay = nil;
    }
}

// display each of the bytes in the view advancing cursor position
- (void)displayData:(NSData *)data {
    
    if(dataForDisplay == nil)
        dataForDisplay = [data mutableCopy];
    else
        [dataForDisplay appendData:data];

    // processDataChunk is a method that can proceed with display until it should break,
    // e.g. to facilitate terminal animation or other ancient tricks.
    [self processDataChunk];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        terminalRows = [NSMutableArray array];
        NSMutableArray *terminalRow;
        CGFloat xPos;
        CGFloat yPos;
        int i, j;
        
        for(i = 0; i < kTerminalRows; i++) {
            
            terminalRow = [NSMutableArray array];
            yPos = (CGFloat)(i * kGlyphHeight);
            
            for(j = 0; j < kTerminalColumns; j++) {
                
                xPos = (CGFloat)(j * kGlyphWidth);
                
                UILabel *glyph = [[NoAALabel alloc] initWithFrame:CGRectMake(xPos, yPos, kGlyphWidth, kGlyphHeight)];
                glyph.font = [UIFont fontWithName:@"Courier New" size:kGlyphFontSize];
                glyph.textColor = [UIColor whiteColor];
                glyph.backgroundColor = [UIColor blackColor];
                glyph.text = nil;

                [terminalRow addObject:glyph];
                [self addSubview:glyph];
            }
            [terminalRows addObject:terminalRow];
        }
        
        CGRect selfFrame = self.frame;
        selfFrame.size.width = kGlyphWidth * (CGFloat)kTerminalColumns;
        selfFrame.size.height = kGlyphHeight * (CGFloat)kTerminalRows;
        self.frame = selfFrame;
        
        cursorColumn = cursorRow = 0;
        
        cursor = [[terminalRows objectAtIndex:cursorRow] objectAtIndex:cursorColumn];
        cursor.backgroundColor = [UIColor grayColor];

        dataForDisplay = [[NSMutableData alloc] init];
    }
    return self;
}

@end
