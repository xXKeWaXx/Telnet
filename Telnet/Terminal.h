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
    
    int termRow;
    int termCol;

    NSMutableArray *tabStops;
    
    int terminalColumns;
    int terminalRows;
    
}

@property id<DisplayDelegate> __weak displayDelegate;
@property id<ConnectionDelegate> __weak connectionDelegate;

@end
