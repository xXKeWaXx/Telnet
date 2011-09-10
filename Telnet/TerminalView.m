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


/************************* terminal display private ***********************/

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        /* this belongs in the terminal identity interpreter
         commandSequenceHandlerDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
         cursorMoveDown, @"B",
         cursorAbsolutePosition, @"H",
         doClearLine, @"J",
         setTextAttributes, @"m",
         setWindow, @"r",
         nil];
         #define kNVTSpecialCharNUL  (0)
         #define kNVTSpecialCharLF   (10)
         #define kNVTSpecialCharCR   (13)
         
         
         */
        
        terminalRows = [NSMutableArray array];
        NSMutableArray *terminalArray;
        CGFloat xPos;
        CGFloat yPos;
        int i, j;
        
        // terminal rows are numbered from 1..kTerminalRows
        for(i = 1; i <= kTerminalRows; i++) {
            
            terminalArray = [NSMutableArray array];
            yPos = (CGFloat)(i * kGlyphHeight);
            
            // terminal columns are numbered from 1..kTerminalColumns
            for(j = 1; j <= kTerminalColumns; j++) {
                
                xPos = (CGFloat)(j * kGlyphWidth);
                
                NoAALabel *glyph = [[NoAALabel alloc] initWithFrame:CGRectMake(xPos, yPos, kGlyphWidth, kGlyphHeight)];
                glyph.font = [UIFont fontWithName:@"Courier New" size:kGlyphFontSize];
                glyph.textColor = [UIColor whiteColor];
                glyph.backgroundColor = [UIColor blackColor];
                glyph.text = nil;
                glyph.row = i;
                glyph.column = j;
                [terminalArray addObject:glyph];
                [self addSubview:glyph];
            }
            [terminalRows addObject:terminalArray];
        }
        
        CGRect selfFrame = self.frame;
        selfFrame.size.width = kGlyphWidth * (CGFloat)kTerminalColumns;
        selfFrame.size.height = kGlyphHeight * (CGFloat)kTerminalRows;
        self.frame = selfFrame;
        
        // home is 1,1
        [self cursorSetRow:1 column:1];
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

#pragma mark -
#pragma mark private stuff

// to avoid off-by-1 errors, array access is always done through these functions
static inline int rowIndex(int rowNumber) { return rowNumber - 1; }
static inline int colIndex(int colNumber) { return colNumber - 1; }

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

- (void)clearRow:(int)row {
    
    NSArray *terminalRowArray = [terminalRows objectAtIndex:rowIndex(row)];
    for(NoAALabel *glyph in terminalRowArray) {
        [self clearGlyph:glyph];
    }
}

#pragma mark -
#pragma mark TerminalDisplayDelegate methods

// CHARACTER DISPLAY
- (void)characterDisplay:(unsigned char)c {

    // current cursor position
    NoAALabel *cursorGlyph = [[terminalRows objectAtIndex:rowIndex(terminalRow)] objectAtIndex:colIndex(terminalColumn)];
    // transform character into alternate sets if required (e.g. codepage 437)
    cursorGlyph.text = [NSString stringWithFormat:@"%c", c];
    // apply current styles to cursor
    // advance cursor position obeying wrap settings
    if(terminalColumn < kTerminalColumns)
        terminalColumn++;
}

- (void)characterNonDisplay:(unsigned char)c {

    // perform whatever action is required by the non-printing character received
    switch(c) {
        case kTelnetCharCR:     // advance row (possibly scrolling) and move to column 1
            [self cursorSetRow:terminalRow + 1 column:1];
            break;
        case kTelnetCharFF:
        case kTelnetCharVT:
        case kTelnetCharLF:     // advance row (possibly scrolling) in same column
            break;
        case kTelnetCharHT:     // Next horizontal tabstop or right margin if there are no more
            break;
        case kTelnetCharBS:     // Backspace
            break;
        case kTelnetCharBEL:    // ding!
            break;
        case kTelnetCharNUL:
        default:
            break;
    }

}

// CURSOR MOVEMENT

// Set cursor to arbitrary position
- (void)cursorSetRow:(int)row column:(int)col {

    if(row > kTerminalRows) {
//        [self scrollUp];
        row = kTerminalRows;
    }
    
    // remove cursor indicator from old cursor position
    NoAALabel *oldCursorGlyph = [[terminalRows objectAtIndex:rowIndex(row)] objectAtIndex:colIndex(col)];
    oldCursorGlyph.textColor = [UIColor blackColor]; // TODO
    
    // record cursor position
    terminalRow = row;
    terminalColumn = col;
    
    // display cursor indicator at new cursor position
    NoAALabel *newCursorGlyph = [[terminalRows objectAtIndex:rowIndex(row)] objectAtIndex:colIndex(col)];
    newCursorGlyph.textColor = [UIColor yellowColor]; // TODO
}

// move cursor left
- (void)cursorLeft {
    
    if(terminalColumn > 1)
        terminalColumn--;
    [self cursorSetRow:terminalRow column:terminalColumn];
}

// move cursor up
- (void)cursorUp {
    
    if(terminalRow > 1)
        terminalRow--;
    [self cursorSetRow:terminalRow column:terminalColumn];
}

// move cursor right
- (void)cursorRight {
    
    if(terminalColumn < kTerminalColumns)
        terminalColumn++;
    [self cursorSetRow:terminalRow column:terminalColumn];
}

// move cursor down
- (void)cursorDown {
    
    if(terminalRow < kTerminalRows)
        terminalRow++;
    [self cursorSetRow:terminalRow column:terminalColumn];
}

// CLEAR

// clear to left of cursor
- (void)clearCursorLeft {
    
    // get array for row
    NSArray *rowArray = [terminalRows objectAtIndex:rowIndex(terminalRow)];
    NoAALabel *glyph;
    
    // to left of, not including, current glyph
    for(int i = 1; i < terminalColumn; i++) {
        glyph = [rowArray objectAtIndex:colIndex(i)];
        [self clearGlyph:glyph];
    }
}

// clear to right of cursor
- (void)clearCursorRight {
    
    // get array for row
    NSArray *rowArray = [terminalRows objectAtIndex:rowIndex(terminalRow)];
    NoAALabel *glyph;
    
    // to right of, not including, current glyph
    for(int i = terminalColumn + 1; i <= kTerminalColumns; i++) {
        glyph = [rowArray objectAtIndex:colIndex(i)];
        [self clearGlyph:glyph];
    }
}

// clear line
- (void)clearRow {
    
    [self clearRow:terminalRow];
}

- (void)clearAll {
    
    for(int i = 1; i <= kTerminalRows; i++) {
        [self clearRow:i];
    }
}

// clear above cursor
- (void)clearCursorAbove {

    for(int i = 1; i < terminalRow; i++) {
        [self clearRow:i];
    }
}

// clear below cursor
- (void)clearCursorBelow {

    for(int i = terminalRow + 1; i <= kTerminalRows; i++) {
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
