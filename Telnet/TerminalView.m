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

@synthesize cursor;
@synthesize terminalRows;
@synthesize windowBegins;
@synthesize windowEnds;
@synthesize textIsBright;
@synthesize textIsDim;
@synthesize textIsUnderscore;
@synthesize textIsBlink;
@synthesize textIsReverse;
@synthesize textIsHidden;

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

typedef enum _CommandState {
    kCommandStart,
    kCommandNumeric
} CommandState;

typedef void (^CommandSequenceHandler)(NSArray *, TerminalView *term);

static void (^cursorMoveDown)(NSArray *, TerminalView *) = ^(NSArray *numericValues, TerminalView *term) { 
    
    int rows = [[numericValues objectAtIndex:0] intValue];
    for(int i = 0; i < rows; i++) {
        [term incrementCursorRow];
    }
};
static void (^setTextAttributes)(NSArray *, TerminalView *) = ^(NSArray *numericValues, TerminalView *term) { 

    for(NSNumber *number in numericValues) {
        int value = [number intValue];
        switch(value) {
            case kTextAtributeClear:
                term.textIsBright = NO;
                term.textIsDim = NO;
                term.textIsUnderscore = NO;
                term.textIsBlink = NO;
                term.textIsReverse = NO;
                term.textIsHidden = NO;
                
            case kTextAttributeBright:
                term.textIsBright = YES;
                term.textIsDim = NO;
                break;
            case kTextAttributeDim:
                term.textIsDim = YES;
                term.textIsBright = NO;
                break;
            case kTextAttributeUnderscore:
                term.textIsUnderscore = YES;
                break;
            case kTextAttributeBlink:
                term.textIsBlink = YES;
                break;
            case kTextAttributeReverse:
                term.textIsReverse = YES;
                break;
            case kTextAttributeHidden:
                term.textIsHidden = YES;
                break;
            default:
                break;
        }
    }
};

static void (^setWindow)(NSArray *, TerminalView *) = ^(NSArray *numericValues, TerminalView *term) { 
    term.windowBegins = [[numericValues objectAtIndex:0] intValue];
    term.windowEnds = [[numericValues objectAtIndex:1] intValue];
};

static void (^doClearLine)(NSArray *, TerminalView *) = ^(NSArray *numericValues, TerminalView *term) { 
    
    int argument = [[numericValues objectAtIndex:0] intValue];
    NSArray *columns;
    
    switch(argument) {
        case 0: // clear screen from cursor down
            // clear from cursor to end of line
            columns = [term.terminalRows objectAtIndex:term.cursor.row];
            for(int i = term.cursor.column; i < kTerminalColumns; i++) {
                NoAALabel *glyph = [columns objectAtIndex:i];
                [glyph erase];
            }
            // then clear all rows below
            for(int i = term.cursor.row; i < kTerminalRows; i++) {
                NSArray *rowArray = [term.terminalRows objectAtIndex:i];
                for(NoAALabel *glyph in rowArray) {
                    [glyph erase];
                }
            }
            break;
        case 1: // clear screen from cursor up
            // clear all rows above
            for(int i = 0; i < term.cursor.row; i++) {
                NSArray *rowArray = [term.terminalRows objectAtIndex:i];
                for(NoAALabel *glyph in rowArray) {
                    [glyph erase];
                }
            }
            // then clear up to cursor
            columns = [term.terminalRows objectAtIndex:term.cursor.row];
            for(int i = 0; i < term.cursor.column; i++) {
                NoAALabel *glyph = [columns objectAtIndex:i];
                [glyph erase];
            }
            break;
        case 2: // clear entire screen
            for(NSMutableArray *array in term.terminalRows) {
                for(NoAALabel* glyph in array) {
                    [glyph erase];
                }
            }
            break;
        default:
            break;
    }

};

- (void)processANSICommandSequence:(unsigned char *)sequence withLength:(int)len {
    
    NSString *commandIdentifier = [NSString string];
    NSMutableArray *numericValues = [NSMutableArray array];
    CommandState state = kCommandStart;
    int numeric;
    
    while(len--) {
        
        unsigned char d = *sequence++;
        switch(state) {
            case kCommandStart:
                if(d >= 060 && d <= 071) {
                    // starting a numeric sequence
                    state = kCommandNumeric;
                    numeric = d - 060;
                } else {
                    // process command 
                    commandIdentifier = [commandIdentifier stringByAppendingFormat:@"%c", d];
                }
                break;
            case kCommandNumeric:
                if(d >= 060 && d <= 071) {
                    // continuing a numeric sequence
                    numeric *= 10;
                    numeric += d - 060;
                } else if (d == ';') {
                    // a compound argument command. Add the numeric received so far to an array of
                    // values and clear the value for a possible next value
                    [numericValues addObject:[NSNumber numberWithInt:numeric]];
                    numeric = 0;
                    
                } else {
                    if(numeric > 0) {
                        [numericValues addObject:[NSNumber numberWithInt:numeric]];
                    }
                    commandIdentifier = [commandIdentifier stringByAppendingFormat:@"%c", d];
                    state = kCommandStart;
                }
                break;
        }
    }
    
    // leaving this loop implies that a command has ended. Are there any commands that remain ambiguous?
    CommandSequenceHandler handler = [commandSequenceHandlerDictionary objectForKey:commandIdentifier];
    if(handler != nil) {
        // need to pass the values accompanying this command and the terminal to operate on
        handler(numericValues, self);
    } else {
        NSLog(@"Unhandled ANSICommand: %@", commandIdentifier);
        if([numericValues count] > 0)
            NSLog(@"%@", numericValues);
    }
}

- (void)processDECCommandSequence:(unsigned char *)sequence withLength:(int)len {
    NSString *commandDebugString = [NSString string];
    
    while(len--) {
        commandDebugString = [commandDebugString stringByAppendingFormat:@"%c", *sequence++];
    }
    NSLog(@"DECCommand: %@", commandDebugString);
}

- (void)processCommandSequence:(NSData *)command {
    
    unsigned char * c = (unsigned char *)[command bytes];
    int len = [command length];
    
    if(*c++ != 033) {
        NSLog(@"command must start with ESC");
        return;
    }
    len--;
    
    if(*c == '[') {
        // eat the '['
        [self processANSICommandSequence:++c withLength:--len];
    } else {
        [self processDECCommandSequence:c withLength:len];
    }
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

        commandSequenceHandlerDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                            cursorMoveDown, @"B",
                                            doClearLine, @"J",
                                            setTextAttributes, @"m",
                                            setWindow, @"r",
                                            nil];
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
                
                NoAALabel *glyph = [[NoAALabel alloc] initWithFrame:CGRectMake(xPos, yPos, kGlyphWidth, kGlyphHeight)];
                glyph.font = [UIFont fontWithName:@"Courier New" size:kGlyphFontSize];
                glyph.textColor = [UIColor whiteColor];
                glyph.backgroundColor = [UIColor blackColor];
                glyph.text = nil;
                glyph.row = i;
                glyph.column = j;
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
