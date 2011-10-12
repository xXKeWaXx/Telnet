//
//  Parser.h
//  xterminal
//
//  Created by Adam Eberbach on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "TelnetConnection.h"
#import "ParserDelegate.h"

@protocol TerminalDelegate <NSObject>
- (void)characterDisplay:(unsigned char)c;
- (void)characterNonDisplay:(unsigned char)c;
- (void)processCommand:(NSData *)command;
- (void)reset;

@end

@interface Parser : NSObject <ParserDelegate> {
    
    NSMutableData *incomingData;
    id<TerminalDelegate> __weak terminalDelegate;

}

@property id<TerminalDelegate> __weak terminalDelegate;

@end
