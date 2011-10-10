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

@synthesize decawm;

/************************* terminal display private ***********************/

// to avoid off-by-1 errors, array access is always done through these functions
static inline int rowIndex(int rowNum) { return rowNum - 1; }
static inline int colIndex(int colNum) { return colNum - 1; }

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        terminalRows = [NSMutableArray array];
        NSMutableArray *terminalArray;
        CGFloat xPos = 0.f;
        CGFloat yPos = 0.f;
        int i, j;
        
        // terminal rows are numbered from 1..kTerminalRows
        for(i = 1; i <= kTerminalRows; i++) {
            
            terminalArray = [NSMutableArray array];

            // terminal columns are numbered from 1..kTerminalColumns
            for(j = 1; j <= kTerminalColumns; j++) {

                NoAALabel *glyph = [[NoAALabel alloc] initWithFrame:CGRectMake(xPos, yPos, kGlyphWidth, kGlyphHeight)];
                glyph.font = [UIFont fontWithName:@"Courier New" size:kGlyphFontSize];
                glyph.textColor = [UIColor whiteColor];
                glyph.backgroundColor = [UIColor blackColor];
                glyph.text = nil;
                glyph.row = i;
                glyph.column = j;
                [terminalArray addObject:glyph];
                [self addSubview:glyph];
                xPos += kGlyphWidth;
            }
            [terminalRows addObject:terminalArray];
            yPos += kGlyphHeight;
            xPos = 0.f;
        }
        
        // tab stops are initially every 8 characters beginning in the first column
        int tabStop = 1;
        tabStops = [[NSMutableArray alloc] init];
        do {
            
            [tabStops addObject:[NSNumber numberWithInt:tabStop]];
            tabStop += 8;
            
        }while(tabStop < kTerminalColumns);
        
        
        CGRect selfFrame = self.frame;
        selfFrame.size.width = kGlyphWidth * (CGFloat)kTerminalColumns;
        selfFrame.size.height = kGlyphHeight * (CGFloat)kTerminalRows;
        self.frame = selfFrame;
        
        // cursor home, attributes reset
        [self displayReset];
    }
    return self;
}

// clear current glyph
- (void)clearGlyph:(NoAALabel *)glyph {
    
    glyph.backgroundColor = backgroundColor;
    glyph.textColor = foregroundColor;
    glyph.text = nil;
}

// remove cursor attributes from current position
- (void)cursorOff {
    
    NoAALabel *cursorGlyph = [[terminalRows objectAtIndex:rowIndex(_terminalRow)] 
                                            objectAtIndex:colIndex(_terminalColumn)];
    cursorGlyph.textColor = foregroundColor;
    cursorGlyph.backgroundColor = backgroundColor;
}

// display cursor attributes in current position
- (void)cursorOn {
    
    NoAALabel *cursorGlyph = [[terminalRows objectAtIndex:rowIndex(_terminalRow)] 
                              objectAtIndex:colIndex(_terminalColumn)];
    cursorGlyph.textColor = backgroundColor;
    cursorGlyph.backgroundColor = foregroundColor;
}

// save the outgoing roll to the scrollback buffer, move top row to bottom (reuse) and move all glyphs up
- (void)scrollUp {
    
    NSMutableArray *topLine = [terminalRows objectAtIndex:0];
    [terminalRows removeObjectAtIndex:0];
    
    // save text from topLine in the scroll buffer
    
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

- (void)scrollDown {
 
    NSLog(@"Can't scroll down yet!");
}

- (void)clearRow:(int)row {
    
    NSArray *terminalRowArray = [terminalRows objectAtIndex:rowIndex(row)];
    for(NoAALabel *glyph in terminalRowArray) {
        [self clearGlyph:glyph];
    }
}

#pragma mark -
#pragma mark TerminalDisplayDelegate methods

// CHARACTER DISPLAY

- (void)fillScreenWithChar:(unsigned char)c {

    NSString *contents = [NSString stringWithFormat:@"%c", c];
    for(int i = 1; i <= kTerminalRows; i++) {
        for(int j = 1; j < kTerminalColumns; j++) {
            NoAALabel *cursorGlyph = [[terminalRows objectAtIndex:rowIndex(i)] objectAtIndex:colIndex(j)];
            cursorGlyph.text = contents;
        }
    }
}

- (void)characterDisplay:(unsigned char)c {

    // current cursor position
    NoAALabel *cursorGlyph = [[terminalRows objectAtIndex:rowIndex(_terminalRow)] objectAtIndex:colIndex(_terminalColumn)];
    
    // transform character into alternate sets if required (e.g. codepage 437) TODO
    cursorGlyph.text = [NSString stringWithFormat:@"%c", c];
    
    // apply current styles to cursor TODO

    if(_terminalColumn < kTerminalColumns) {
        [self cursorSetRow:_terminalRow column:_terminalColumn + 1];
    } else if(_terminalColumn == kTerminalColumns && decawm == YES) {
        // if position is last column and wrap enabled, wrap
        [self cursorSetRow:_terminalRow + 1 column:1];
    }
}

- (void)characterNonDisplay:(unsigned char)c {

    // perform whatever action is required by the non-printing character received
    switch(c) {
        case kTelnetCharCR:     // move to column 1, carriage return
            [self cursorSetRow:_terminalRow column:1];
            break;
        case kTelnetCharFF:     // advance row, remain in same column
        case kTelnetCharVT:
            [self advanceRow];
            break;
        case kTelnetCharLF:     // advance row, carriage return
            [self advanceRow];
            [self cursorSetRow:_terminalRow column:1];
            break;
        case kTelnetCharHT:     // Next horizontal tabstop or right margin if there are no more
        {
            // look for next tabstop after current column position
            int tabFound = 0;
            for(NSNumber *tabStopNumber in tabStops) {
                if([tabStopNumber intValue] > _terminalColumn) {
                    tabFound = [tabStopNumber intValue];
                    break;
                }
            }
            if(tabFound != 0) {
                // tab found, jump to it
                [self cursorSetRow:_terminalRow column:tabFound]; 
            } else {
                // not found, go to margin
                [self cursorSetRow:_terminalRow column:kTerminalColumns];
            }
        }
            break;
        case kTelnetCharBS:     // Backspace
        {
            if(_terminalColumn > 1) {
                // erase glyph at previous position
                NSArray *rowArray = [terminalRows objectAtIndex:rowIndex(_terminalRow)];
//                NoAALabel *glyph;
//                glyph = [rowArray objectAtIndex:colIndex(_terminalColumn - 1)];
//                [self clearGlyph:glyph];

                // move cursor left
                [self cursorLeft];
            }
        }
            break;
        case kTelnetCharBEL:    // ding!
            break;
        case kTelnetCharNUL:
            NSLog(@"NUL");
        default:
            break;
    }
}

// CURSOR MOVEMENT

// the cursor advances downward because of a LF or other 
- (void)advanceRow {
    
    [self cursorOff];
    if(_terminalRow == kTerminalRows) {
        [self scrollUp];
        [self cursorSetRow:_terminalRow column:_terminalColumn];
    } else {
        [self cursorSetRow:_terminalRow + 1 column:_terminalColumn];
    }
    [self cursorOn];
}

// the cursor advances downward because of a LF or other 
- (void)decreaseRow {
    
    [self cursorOff];
    if(_terminalRow == 1) {
        [self scrollDown];
        [self cursorSetRow:1 column:_terminalColumn];
    } else {
        [self cursorSetRow:_terminalRow - 1 column:_terminalColumn];
    }
    [self cursorOn];
}

// Set cursor to arbitrary position
- (void)cursorSetRow:(int)row column:(int)col {

    [self cursorOff];
    
    if(row > kTerminalRows)
        row = kTerminalRows;
    if(col > kTerminalColumns)
        col = kTerminalColumns;
    
    // record cursor position
    _terminalRow = row;
    _terminalColumn = col;
    
    [self cursorOn];
}

- (void)cursorSetColumn:(int)col {
    
    [self cursorSetRow:_terminalRow column:col];
}

// move cursor left
- (void)cursorLeft {
    
    if(_terminalColumn > 1)
        [self cursorSetRow:_terminalRow column:_terminalColumn - 1];
}

// move cursor up
- (void)cursorUp {
    
    if(_terminalRow > 1)
        [self cursorSetRow:_terminalRow - 1 column:_terminalColumn];
}

// move cursor right
- (void)cursorRight {
    
    if(_terminalColumn < kTerminalColumns)
        [self cursorSetRow:_terminalRow column:_terminalColumn + 1];
}

// move cursor down
- (void)cursorDown {
    
    if(_terminalRow < kTerminalRows)
        [self cursorSetRow:_terminalRow + 1 column:_terminalColumn];
}

// set autowrap mode
- (void)setAutoWrapMode:(BOOL)wrap {
    
    decawm = wrap;
}

// CLEAR

// clear to left of cursor
- (void)clearCursorLeft {
   
    // get array for row
    NSArray *rowArray = [terminalRows objectAtIndex:rowIndex(_terminalRow)];
    NoAALabel *glyph;
    
    // to left of, inclusive
    for(int i = 1; i <= _terminalColumn; i++) {
        glyph = [rowArray objectAtIndex:colIndex(i)];
        [self clearGlyph:glyph];
    }
}

// clear to right of cursor
- (void)clearCursorRight {
    
    // get array for row
    NSArray *rowArray = [terminalRows objectAtIndex:rowIndex(_terminalRow)];
    NoAALabel *glyph;
    
    // to right of, inclusive
    for(int i = _terminalColumn; i <= kTerminalColumns; i++) {
        glyph = [rowArray objectAtIndex:colIndex(i)];
        [self clearGlyph:glyph];
    }
}

// clear line
- (void)clearRow {
    
    [self clearRow:_terminalRow];
}

- (void)clearAll {
    
    for(int i = 1; i <= kTerminalRows; i++) {
        [self clearRow:i];
    }
}

// clear beginning of screen to cursor
- (void)clearCursorAbove {

    for(int i = 1; i < _terminalRow; i++) {
        [self clearRow:i];
    }
    
    [self clearCursorLeft];
}

// clear from cursor to end of screen
- (void)clearCursorBelow {

    [self clearCursorRight];

    for(int i = _terminalRow + 1; i <= kTerminalRows; i++) {
        [self clearRow:i];
    }
}

// TERMINAL STATE

// set window area
- (void)terminalWindowSetRowStart:(int)rowStart rowEnd:(int)rowEnd {
    
}

// scroll window up
- (void)terminalWindowScrollUp {
    
}

// scroll window down
- (void)terminalWindowScrollDown {
    
}

// DISPLAY CHARACTERS

// set foreground color
- (void)displaySetForegroundColor:(TerminalDisplayColor)color {
    
    switch(color) {
            
        case kTermColorBlack:
            foregroundColor = [UIColor blackColor];
            break;
        case kTermColorRed:
            foregroundColor = [UIColor redColor];
            break;
        case kTermColorGreen:
            foregroundColor = [UIColor greenColor];
            break;
        case kTermColorYellow:
            foregroundColor = [UIColor yellowColor];
            break;
        case kTermColorBlue:
            foregroundColor = [UIColor blueColor];
            break;
        case kTermColorMagenta:
            foregroundColor = [UIColor magentaColor];
            break;
        case kTermColorCyan:
            foregroundColor = [UIColor cyanColor];
            break;
        case kTermColorWhite:
            foregroundColor = [UIColor whiteColor];
            break;
        default:
            foregroundColor = [UIColor whiteColor];
            break;
    }
}

// set background color
- (void)displaySetBackgroundColor:(TerminalDisplayColor)color {
    
    switch(color) {
            
        case kTermColorBlack:
            backgroundColor = [UIColor blackColor];
            break;
        case kTermColorRed:
            backgroundColor = [UIColor redColor];
            break;
        case kTermColorGreen:
            backgroundColor = [UIColor greenColor];
            break;
        case kTermColorYellow:
            backgroundColor = [UIColor yellowColor];
            break;
        case kTermColorBlue:
            backgroundColor = [UIColor blueColor];
            break;
        case kTermColorMagenta:
            backgroundColor = [UIColor magentaColor];
            break;
        case kTermColorCyan:
            backgroundColor = [UIColor cyanColor];
            break;
        case kTermColorWhite:
            backgroundColor = [UIColor whiteColor];
            break;
        default:
            backgroundColor = [UIColor blackColor];
            break;
    }
}

// reset to basic state
- (void)displayReset {
    
    [self displaySetForegroundColor:kTermColorWhite];
    [self displaySetBackgroundColor:kTermColorBlack];
    // this is the only place where row & column may be set
    _terminalRow = _terminalColumn = 1;
    
    decawm = NO;
    
    [self cursorOn];

}


// set display bright
- (void)displaySetTextBright:(BOOL)set {
}

// set display dim
- (void)displaySetTextDim:(BOOL)set {
}

// set display underscore
- (void)displaySetTextUnderscore:(BOOL)set {
}

// set display blink
- (void)displaySetTextBlink:(BOOL)set {
}

// set display reverse
- (void)displaySetTextReverse:(BOOL)set {
}

// set display hidden
- (void)displaySetTextHidden:(BOOL)set {
}

@end
