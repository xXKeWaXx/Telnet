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

// change the frames of all glyphs so they all move up one "line" except for the top row, which has its contents cleared
// and becomes the bottom line
- (void)scrollUp {
    
    NSLog(@"Scrolling up");
    
    CGRect glyphFrame;
    for(UILabel *glyph in glyphs) {
        
        if(glyph.frame.origin.y == 0) {
            
            // top row - gets cleared
            glyph.text = nil;
            glyph.textColor = [UIColor yellowColor];
            // and moved to the bottom row
            glyphFrame = glyph.frame;
            glyphFrame.origin.y = kGlyphHeight * (kTerminalRows - 1);
            glyph.frame = glyphFrame;
            
/*
            if(glyph.frame.origin.x < 1.f)
                NSLog(@"Moving top line to bottom: glyphs at y=%f to ypos %f", 0.f, glyph.frame.origin.y);
*/            
        } else {
            
            // all other rows just get moved up one
            glyphFrame = glyph.frame;
            CGFloat initialYPos = glyph.frame.origin.y;
            glyphFrame.origin.y -= kGlyphHeight;
            glyph.frame = glyphFrame;
/*
            if(glyph.frame.origin.x < 1.f)
                NSLog(@"Moving line up: glyphs at y=%f to ypos %f", initialYPos, glyph.frame.origin.y);
*/
        }
    }
}

- (void)incrementCursorLine {

    if(cursorLine < kTerminalRows - 1) {
        cursorLine++;
    } else {
        NSLog(@"Scrolling up, cursor line remains %d", cursorLine);
        [self scrollUp];
    }
}

- (void)incrementCursorColumn {
    
    if(cursorColumn < kTerminalColumns - 1)
        cursorColumn++;
}

// display each of the bytes in the view advancing cursor position
- (void)displayData:(NSData *)data {
    
    unsigned char *c = (unsigned char *)[data bytes];
    int len = [data length];
    
    NSLog(@"Before data processing: %d,%d", cursorColumn, cursorLine);
    
    while(len--) {

        // get the label at the current cursor position
        UILabel *glyph = [glyphs objectAtIndex:(kTerminalColumns * cursorLine) + cursorColumn];
        unsigned char d = *c++;
        
        switch(d) {
            case kNVTSpecialCharNUL:
                // do nothing
                break;
            case kNVTSpecialCharLF:
                [self incrementCursorLine];
                break;
            case kNVTSpecialCharCR:
                cursorColumn = 0;
                break;
            default:
                glyph.text = [NSString stringWithFormat:@"%c", d];
                [self incrementCursorColumn];
                break;
        }
    }
    
    NSLog(@"After data processing: %d,%d", cursorColumn, cursorLine);

}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        NSMutableArray *createdGlyphs = [[NSMutableArray alloc] initWithCapacity:80*25];
        
        CGFloat xPos;
        CGFloat yPos;
        
        for(int i = 0; i < kTerminalRows*kTerminalColumns; i++) {
            
            xPos = (CGFloat)(i % kTerminalColumns) * kGlyphWidth;
            yPos = (CGFloat)(i / kTerminalColumns) * kGlyphHeight;

            UILabel *glyph = [[NoAALabel alloc] initWithFrame:CGRectMake(xPos, yPos, kGlyphWidth, kGlyphHeight)];

            glyph.font = [UIFont fontWithName:@"Courier New" size:kGlyphFontSize];
            
            glyph.textColor = [UIColor whiteColor];
            glyph.backgroundColor = [UIColor blackColor];
            glyph.text = nil;
            [createdGlyphs addObject:glyph];
            [self addSubview:glyph];
        }
        
        CGRect selfFrame = self.frame;
        selfFrame.size.width = kGlyphWidth * (CGFloat)kTerminalColumns;
        selfFrame.size.height = kGlyphHeight * (CGFloat)kTerminalRows;
        self.frame = selfFrame;
        
        glyphs = (NSArray *)createdGlyphs;
        cursorColumn = cursorLine = 0;
    }
    return self;
}

@end
