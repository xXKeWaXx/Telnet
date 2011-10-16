//
//  Terminal.h
//  xterminal
//
//  Created by Adam Eberbach on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Parser.h"
#import "DisplayDelegate.h"
#import "ConnectionDelegate.h"

@interface Terminal : NSObject <TerminalDelegate> {
    
    id<DisplayDelegate> __weak displayDelegate;
    id<ConnectionDelegate> __weak connectionDelegate;
    
    // current position of cursor
    int termRow;
    int termCol;

    // array of tabstop column value for cursor positioning
    NSMutableArray *tabStops;
    
    // record of the rows and columns currently used by this terminal
    int terminalColumns;
    int terminalRows;
    
}

@property id<DisplayDelegate> __weak displayDelegate;
@property id<ConnectionDelegate> __weak connectionDelegate;

@end
