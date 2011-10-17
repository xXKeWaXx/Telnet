//
//  Display.m
//  xterminal
//
//  Created by Adam Eberbach on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Display.h"
#import "Glyph.h"

@implementation Display

+ (CGSize)sizeForRows:(int)rows andColumns:(int)cols {
    CGSize displaySize = CGSizeMake(cols * kGlyphWidth, rows * kGlyphHeight);
    return displaySize;
}

// to avoid off-by-1 errors, array access is always done through these functions
static inline int rowIndex(int rowNum) { return rowNum - 1; }
static inline int colIndex(int colNum) { return colNum - 1; }

- (void)resetScreenWithRows:(int)rows andColumns:(int)cols {
    
    // set up the glyphs for the requested size
    terminalRows = [NSMutableArray array];
    
    NSMutableArray *terminalArray;
    CGFloat xPos = 0.f;
    CGFloat yPos = 0.f;
    int i, j;
    
    backgroundColor = kGlyphColorBlack;
    foregroundColor = kGlyphColorGreen;
    
    // terminal rows are numbered from 1..kTerminalRows
    for(i = 1; i <= rows; i++) {
        
        terminalArray = [NSMutableArray array];
        
        // terminal columns are numbered from 1..kTerminalColumns
        for(j = 1; j <= cols; j++) {
            
            Glyph *glyph = [[Glyph alloc] initWithFrame:CGRectMake(xPos, yPos, kGlyphWidth, kGlyphHeight)];
            glyph.font = [UIFont fontWithName:@"Courier New" size:kGlyphFontSize];
            glyph.text = nil;
            glyph.textColor = [Glyph UIColorWithGlyphColor:foregroundColor intensity:NO];
            glyph.backgroundColor = [Glyph UIColorWithGlyphColor:backgroundColor intensity:NO];
            
            [terminalArray addObject:glyph];
            [self addSubview:glyph];
            xPos += kGlyphWidth;
        }
        [terminalRows addObject:terminalArray];
        yPos += kGlyphHeight;
        xPos = 0.f;
    }
    
    CGRect selfFrame = self.frame;
    selfFrame.size.width = kGlyphWidth * (CGFloat)cols;
    selfFrame.size.height = kGlyphHeight * (CGFloat)rows;
    self.frame = selfFrame;
}

- (void)clearDisplay {
    
    for(NSArray *row in terminalRows) {
        for(Glyph *glyph in row) {
            [glyph eraseWithBG:backgroundColor];
        }
    }
}

// set terminal width (implies clear)
- (void)setColumns:(int)cols {

    // 80-col only right now but this could cause a complete redraw
    
    [self clearDisplay];
}

- (void)displayChar:(uint8_t)c 
              atRow:(int)row 
           atColumn:(int)col 
     withAttributes:(glyphAttributes)attributes {
    
    if((row > 24) || (col > 80))
        return;
    
    Glyph *glyph = [[terminalRows objectAtIndex:rowIndex(row)] 
                              objectAtIndex:colIndex(col)];
    
    // check attributes, set display

    glyph.text = [NSString stringWithFormat:@"%c", c];

}

// save the outgoing roll to the scrollback buffer, move top row to bottom (reuse) and move all glyphs up
- (void)scrollUp {
    
    int rowCount = [terminalRows count];
    NSMutableArray *topLine = [terminalRows objectAtIndex:0];
    [terminalRows removeObjectAtIndex:0];
    
    // save text from topLine in the scroll buffer
    
    // alter top line to become bottom line, text is cleared and frame.origin.y set
    CGRect glyphFrame;
    CGFloat rowYOrigin = kGlyphHeight * (rowCount - 1);
    for(Glyph* glyph in topLine) {
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

@end
