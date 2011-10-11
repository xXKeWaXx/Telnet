//
//  Terminal.h
//  xterminal
//
//  Created by Adam Eberbach on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Parser.h"

@protocol DisplayDelegate <NSObject>
- (void)resetScreenWithRows:(int)rows andColumns:(int)cols;
- (void)displayChar:(uint8_t)c atRow:(int)row atColumn:(int)col;
@end

@interface Terminal : NSObject <TerminalDelegate> {
    
    id<DisplayDelegate> __weak displayDelegate;
    
}

@property id<DisplayDelegate> __weak displayDelegate;

@end
