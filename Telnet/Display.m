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

- (CGFloat)glyphHeight {
    return kGlyphHeight;
}

- (CGFloat)glyphWidth {
    return kGlyphWidth;
}


// to avoid off-by-1 errors, array access is always done through these functions
static inline int rowIndex(int rowNum) { return rowNum - 1; }
static inline int colIndex(int colNum) { return colNum - 1; }

- (void)toggleBlink:(NSTimer *)blinkTimer {
    
    static BOOL blink = YES;
    
    if(blink == YES)
        blink = NO;
    else
        blink = YES;
    
    for(Glyph *glyph in blinkArray) {

        [glyph toggleBlink:blink];
    }
}

- (void)resetScreenWithRows:(int)rows andColumns:(int)cols {
    
    // set up the glyphs for the requested size
    terminalRows = [NSMutableArray array];
    terminalColumns = cols;
    
    NSMutableArray *terminalArray;
    CGFloat xPos = 0.f;
    CGFloat yPos = 0.f;
    int i, j;
    
    backgroundColor = defaultBackgroundColor = kGlyphColorBlack;
    foregroundColor = defaultForegroundColor = kGlyphColorGreen;
    
    blinkArray = [NSMutableArray arrayWithCapacity:rows * cols];
    blinkTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(toggleBlink:) userInfo:nil repeats:YES];

    normalFont = [UIFont fontWithName:@"CourierNewPSMT" size:kGlyphFontSize];
    boldFont = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:kGlyphFontSize];

    // terminal rows are numbered from 1..kTerminalRows
    for(i = 1; i <= rows; i++) {
        
        terminalArray = [NSMutableArray array];
        
        // terminal columns are numbered from 1..kTerminalColumns
        for(j = 1; j <= cols; j++) {
            
            Glyph *glyph = [[Glyph alloc] initWithFrame:CGRectMake(xPos, yPos, kGlyphWidth, kGlyphHeight)];
            glyph.font = normalFont;
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

- (void)setAttributes:(uint16_t)attributes foreground:(GlyphColor)fg background:(GlyphColor)bg {
 
    currentAttributes = attributes;

    if(fg == kGlyphColorDefault)
        foregroundColor = defaultForegroundColor;
    else 
        foregroundColor = fg;
    
    if(bg == kGlyphColorDefault)
        backgroundColor = defaultBackgroundColor;
    else
        backgroundColor = bg;
}

- (void)displayChar:(uint8_t)c atRow:(int)row atColumn:(int)col {
    
    if((row > [terminalRows count]) || (col > terminalColumns))
        return;
    
    Glyph *glyph = [[terminalRows objectAtIndex:rowIndex(row)] 
                              objectAtIndex:colIndex(col)];
    
    // check attributes, set display
    if(currentAttributes & kModeIntensity) {
        
    }
    
    if(currentAttributes & kModeInverse) {
        glyph.backgroundColor = 
            [Glyph UIColorWithGlyphColor:foregroundColor intensity:(currentAttributes & kModeIntensity)];
        glyph.textColor = [Glyph UIColorWithGlyphColor:backgroundColor intensity:(currentAttributes & kModeIntensity)];
    } else {
        glyph.backgroundColor = 
            [Glyph UIColorWithGlyphColor:backgroundColor intensity:(currentAttributes & kModeIntensity)];
        glyph.textColor = [Glyph UIColorWithGlyphColor:foregroundColor intensity:(currentAttributes & kModeIntensity)];
    }

    if(currentAttributes & kModeBold) {
        glyph.font = boldFont;
    } else {
        glyph.font = normalFont;
    }

    if(currentAttributes & kModeUnderline) {
        glyph.isUnderlined = YES;
    } else {
        glyph.isUnderlined = NO;
    }

    if(currentAttributes & kModeBlink) {
        [blinkArray addObject:glyph];
    } else {
        [blinkArray removeObject:glyph];
    }

    glyph.text = [NSString stringWithFormat:@"%c", c];
}

// save the outgoing row to the scrollback buffer, move top row to bottom (reuse) and move all glyphs up
- (void)scrollUpRegionTop:(int)top regionSpan:(int)rows {
    
    NSMutableArray *topLine = [terminalRows objectAtIndex:rowIndex(top)];
    int lastIndex = top + rows - 1;
    
    // save text of top line to scrollback buffer

    // remove top line of scroll region, it scrolls away
    [terminalRows removeObjectAtIndex:rowIndex(top)];
    
    // recycle old top line to become bottom line, text cleared and frame set
    CGRect glyphFrame;
    CGFloat rowYOrigin = kGlyphHeight * (lastIndex - 1);
    for(Glyph* glyph in topLine) {
        glyph.text = nil;
        glyphFrame = glyph.frame;
        glyphFrame.origin.y = rowYOrigin;
        glyph.frame = glyphFrame;
    }

    // alter frame of all other scrolled lines so that they move up one line
    rowYOrigin = kGlyphHeight * (top - 1);
    for(int i = top; i <= (lastIndex - 1); i++) {
        NSMutableArray *rowArray = [terminalRows objectAtIndex:rowIndex(i)];
        for(UILabel* glyph in rowArray) {
            glyphFrame = glyph.frame;
            glyphFrame.origin.y = rowYOrigin;
            glyph.frame = glyphFrame;
        }
        rowYOrigin += kGlyphHeight;
    }
    
    // re-insert the bottom line
    [terminalRows insertObject:topLine atIndex:rowIndex(lastIndex)];
}

@end
