//
//  TelnetConnection.h
//  Telnet
//
//  Created by Adam Eberbach on 20/08/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

// http://www.iana.org/assignments/terminal-type-names/terminal-type-names.xml

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "TelnetOptionHandler.h"
#import "TelnetConstants.h"

@protocol TerminalConnectionDisplayDelegate
- (void)displayData:(NSData *)data;
@end

// The TelnetConnection object handles the management of the telnet session including the interpretation of
// commands and negotiation of options. A delegate, terminalDelegate, is defined for output of display to the user.

@interface TelnetConnection : NSObject <GCDAsyncSocketDelegate> {

    id<TerminalConnectionDisplayDelegate> __weak _displayDelegate;
    NSMutableDictionary *optionHandlers;
    GCDAsyncSocket *socket;
    long readSequence;
    long writeSequence;
    NSMutableData *dataForDisplay;
    TelnetState receiveState;
    BOOL inSynch;
    // Subnegotiation of options
    TelnetOption subnegotiationType;
    int subnegotiationLen;
    NSMutableData *dataForSubnegotiation;
}

- (void)open:(NSString *)hostName port:(unsigned long)port;
- (void)send:(NSString *)sendData;
- (void)read;
- (void)setOptions:(NSString *)jsonOptions;

@property id<TerminalConnectionDisplayDelegate> __weak displayDelegate;

@end
