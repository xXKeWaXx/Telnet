//
//  Terminal.h
//  xterminal
//
//  Created by Adam Eberbach on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Parser.h"

typedef uint16_t glyphAttributes;

@protocol DisplayDelegate <NSObject>
- (void)resetScreenWithRows:(int)rows andColumns:(int)cols;
- (void)displayChar:(uint8_t)c 
              atRow:(int)row 
           atColumn:(int)col 
     withAttributes:(glyphAttributes)attributes;
@end

@interface Terminal : NSObject <TerminalDelegate> {
    
    id<DisplayDelegate> __weak displayDelegate;
    
    int termRow;
    int termCol;

    NSMutableArray *tabStops;
    
    int terminalColumns;
    int terminalRows;
    
}

@property id<DisplayDelegate> __weak displayDelegate;

@end
