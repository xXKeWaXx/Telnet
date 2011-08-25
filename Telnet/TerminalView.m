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

- (void)processDataChunk {
    
    unsigned char *c = (unsigned char *)[dataForDisplay bytes];
    int len = [dataForDisplay length];
    
    // count determines how many characters will be displayed before allowing the run loop to update display
    int count = kTerminalColumns;

    while(--count && len--)  {
        
        unsigned char d = *c++;
        switch(d) {
            case kNVTSpecialCharNUL:
                break;
            case kNVTSpecialCharLF:
                [self incrementCursorRow];
                break;
            case kNVTSpecialCharCR:
                cursorColumn = 0;
                [self cursorMoveToRow:cursorRow toCol:cursorColumn];

                break;
            default:
            {
                UILabel *glyph = [[terminalRows objectAtIndex:cursorRow] objectAtIndex:cursorColumn];
                glyph.text = [NSString stringWithFormat:@"%c", d];
                [self incrementCursorColumn];
            }
                break;
        }
    }
    
    if(len > 0) {
        
        dataForDisplay = [NSMutableData dataWithBytes:c length:len];
        
        // more data to display, allow run loop to continue and return here
        [self performSelector:@selector(processDataChunk) withObject:nil afterDelay:0.1f];
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
