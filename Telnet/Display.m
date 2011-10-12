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
    
    // terminal rows are numbered from 1..kTerminalRows
    for(i = 1; i <= rows; i++) {
        
        terminalArray = [NSMutableArray array];
        
        // terminal columns are numbered from 1..kTerminalColumns
        for(j = 1; j <= cols; j++) {
            
            Glyph *glyph = [[Glyph alloc] initWithFrame:CGRectMake(xPos, yPos, kGlyphWidth, kGlyphHeight)];
            glyph.font = [UIFont fontWithName:@"Courier New" size:kGlyphFontSize];
            glyph.text = nil;
            glyph.backgroundColor = [UIColor blackColor];
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

- (void)displayChar:(uint8_t)c 
              atRow:(int)row 
           atColumn:(int)col 
     withAttributes:(glyphAttributes)attributes {
    
    Glyph *glyph = [[terminalRows objectAtIndex:rowIndex(row)] 
                              objectAtIndex:colIndex(col)];
    
    // check attributes, set display
    glyph.textColor = [UIColor whiteColor];
    glyph.backgroundColor = [UIColor blackColor];

    glyph.text = [NSString stringWithFormat:@"%c", c];

}
@end
