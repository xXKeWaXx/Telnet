//
//  TelnetConnection.h
//  Telnet
//
//  Created by Adam Eberbach on 20/08/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@protocol TerminalConnectionDisplayDelegate
- (void)displayData:(NSData *)data;
@end

// special characters used in telnet protocol

#define kTelnetCharIAC  (255) // interpret as command
#define kTelnetCharDONT (254) // demands other party stop or confirms other party no longer expected to perform an option
#define kTelnetCharDO   (253) // requests other party perform or confirms expectation other party will perform an option
#define kTelnetCharWONT (252) // refusal to perform or continue performing an option
#define kTelnetCharWILL (251) // wants to begin, or confirms are now performing an option
#define kTelnetCharSB   (250) // subnegotiation follows
#define kTelnetCharGA   (249) // go ahead
#define kTelnetCharEL   (248) // erase line
#define kTelnetCharEC   (247) // erase character
#define kTelnetCharAYT  (246) // are you there?
#define kTelnetCharAO   (245) // abort output
#define kTelnetCharIP   (244) // interrupt process
#define kTelnetCharBRK  (243) // break
#define kTelnetCharDM   (242) // data mark (always accompanied by TCP urgent notification)
#define kTelnetCharNOP  (241) // no operation
#define kTelnetCharSE   (240) // end subnegotiation paramaters
#define kTelnetCharCR   (13)  // ASCII CR carriage return
#define kTelnetCharFF   (12)  // ASCII FF form feed
#define kTelnetCharVT   (11)  // ASCII VT vertical tab
#define kTelnetCharLF   (10)  // ASCII LF line feed
#define kTelnetCharHT   (9)   // ASCII HT horizontal tab
#define kTelnetCharBS   (8)   // ASCII BS backspace
#define kTelnetCharBEL  (7)   // ASCII BEL bell
#define kTelnetCharNUL  (0)   // ASCII NUL

// buffer size to use when processing input from network
#define kTelnetReadBufferSize (2048)

#define kTelnetMsgConnecting    ("Connecting...")

typedef enum _TelnetState {

    kStateStart,
    kStateSeenCR,
    kStateSeenIAC,
    kStateSeenDO,
    kStateSeenDONT,
    kStateSeenWILL,
    kStateSeenWONT,
    kStateSeenSB,
    kStateSubnegotiating,
    kStateSubnegotiatingSeenIAC
    
} TelnetState;

// The TelnetConnection object handles the management of the telnet session including the interpretation of
// commands and negotiation of options. A delegate, terminalDelegate, is defined for output of display to the user.

@interface TelnetConnection : NSObject <GCDAsyncSocketDelegate> {

    id<TerminalConnectionDisplayDelegate> __weak _displayDelegate;
    GCDAsyncSocket *socket;
    long readSequence;
    long writeSequence;
    NSMutableData *dataForDisplay;
    TelnetState receiveState;
    BOOL inSynch;
}

- (void)open:(NSString *)hostName port:(unsigned long)port;
    
@property id<TerminalConnectionDisplayDelegate> __weak displayDelegate;

@end
