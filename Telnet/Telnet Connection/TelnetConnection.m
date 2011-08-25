//
//  TelnetConnection.m
//  Telnet
//
//  Created by Adam Eberbach on 20/08/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TelnetConnection.h"

@implementation TelnetConnection

@synthesize displayDelegate = _displayDelegate;

- (id)init {
    
    self = [super init];
    if(self) {
     
        readSequence = writeSequence = 0;
        inSynch = NO;
        receiveState = kStateStart;
    }
    return self;
}

- (void)open:(NSString *)hostName port:(unsigned long)port {
    
    socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *error;
    [socket connectToHost:hostName onPort:port error:&error];

    NSData *display = [NSData dataWithBytes:kTelnetMsgConnecting length:strlen(kTelnetMsgConnecting)];
    [_displayDelegate displayData:display];
}

#define SEND_BUFSIZE (600)

- (void)read {
    [socket readDataWithTimeout:-1 tag:readSequence++];

}

- (void)send:(NSString *)sendData {

    const char *buf = [sendData cStringUsingEncoding:NSASCIIStringEncoding];

    NSData *data = [[NSData alloc] initWithBytes:buf length:[sendData length]];
    [socket writeData:data withTimeout:-1 tag:writeSequence++];
}

- (void)sendOption:(unsigned char)option command:(unsigned char)cmd {
    
    unsigned char commandBuf[3];
    *(commandBuf + 0) = kTelnetCharIAC;
    *(commandBuf + 1) = cmd;
    *(commandBuf + 2) = option;
    
    NSLog(@"Sent IAC %d %d", cmd, option);
    
    NSData *optionData = [[NSData alloc] initWithBytes:commandBuf length:3];
    [socket writeData:optionData withTimeout:-1 tag:writeSequence++];
}

- (void)processOption:(unsigned char)option command:(unsigned char)cmd {
    
    if(cmd == kTelnetCharWILL) {
        [self sendOption:option command:kTelnetCharDONT];
    } else if(cmd == kTelnetCharDO) {
        [self sendOption:option command:kTelnetCharWONT];
    }
}

// GCDAsyncSocket delegate

// connection succeeded
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    
    [sock readDataWithTimeout:-1 tag:readSequence++];
}


// incoming data
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {

    if(dataForDisplay == nil)
        dataForDisplay = [[NSMutableData alloc] init];
    
    // data is NSData not NSMutableData, bytes cannot actually be modified through buf, the cast hides a warning
    char *buf = (char *)[data bytes];
    int len = [data length];

    NSLog(@"Telnet received %d characters", len);

    // process every character switching state as necessary
    while (len--) {
        int c = (unsigned char)*buf++;
        
        switch (receiveState) {
                
            case kStateStart:
            case kStateSeenCR:
                if (c == kTelnetCharNUL && receiveState == kStateSeenCR)
                    receiveState = kStateStart;
                else if (c == kTelnetCharIAC)
                    receiveState = kStateSeenIAC;
                else {
                    if (inSynch == NO) {
                        // normal data to pass through for display by terminal
                        [dataForDisplay appendBytes:&c length:1];
                    }                    
#if 1
                    /* I can't get the F***ing winsock to insert the urgent IAC
                     * into the right position! Even with SO_OOBINLINE it gives
                     * it to recv too soon. And of course the DM byte (that
                     * arrives in the same packet!) appears several K later!!
                     *
                     * Oh well, we do get the DM in the right place so I'll
                     * just stop hiding on the next 0xf2 and hope for the best.
                     */
                    else if (c == kTelnetCharDM)
                        inSynch = NO;
#endif
/*                    
 // to do with telnet binary (8-bit data path option)
                    if (c == kTelnetCharCR && telnet->opt_states[o_they_bin.index] != ACTIVE)
                        receiveState = kStateSeenCR;
                    else
                        receiveState = kStateStart;
 */
                }
                break;
            case kStateSeenIAC:
                if (c == kTelnetCharDO)
                    receiveState = kStateSeenDO;
                else if (c == kTelnetCharDONT)
                    receiveState = kStateSeenDONT;
                else if (c == kTelnetCharWILL)
                    receiveState = kStateSeenWILL;
                else if (c == kTelnetCharWONT)
                    receiveState = kStateSeenWONT;
                else if (c == kTelnetCharSB)
                    receiveState = kStateSeenSB;
                else if (c == kTelnetCharDM) {
                    inSynch = NO;
                    receiveState = kStateStart;
                } else {
                    if (c == kTelnetCharIAC) {
                        // the case of IAC sent twice (escaped)
                        [dataForDisplay appendBytes:&c length:1];
                    }
                    receiveState = kStateStart;
                }
                break;
            case kStateSeenWILL:
                NSLog(@"Received IAC WILL %d", c);
                [self processOption:c command:kTelnetCharWILL];
                receiveState = kStateStart;
                break;
            case kStateSeenWONT:
                NSLog(@"Received IAC WONT %d", c);
                [self processOption:c command:kTelnetCharWONT];
                receiveState = kStateStart;
                break;
            case kStateSeenDO:
                NSLog(@"Received IAC DO %d", c);
                [self processOption:c command:kTelnetCharDO];
                receiveState = kStateStart;
                break;
            case kStateSeenDONT:
                NSLog(@"Received IAC DONT %d", c);
                [self processOption:c command:kTelnetCharDONT];
                receiveState = kStateStart;
                break;
            case kStateSeenSB:
            case kStateSubnegotiating:
            case kStateSubnegotiatingSeenIAC:
                NSLog(@"Inconceivable!");
                break;
/*                
            case kStateSeenSB:
                telnet->sb_opt = c;
                telnet->sb_len = 0;
                receiveState = kStateSubnegotiating;
                break;
            case kStateSubnegotiating:
                if (c == kTelnetCharIAC)
                    receiveState = kStateSubnegotiatingSeenIAC;
                else {
                subneg_addchar:
                    if (telnet->sb_len >= telnet->sb_size) {
                        telnet->sb_size += SB_DELTA;
                        telnet->sb_buf = sresize(telnet->sb_buf, telnet->sb_size,
                                                 unsigned char);
                    }
                    telnet->sb_buf[telnet->sb_len++] = c;
                    receiveState = kStateSubnegotiating;	// in case we came here by goto
                }
                break;
            case kStateSubnegotiatingSeenIAC:
                if (c != kTelnetCharSE)
                    goto subneg_addchar;   // yes, it's a hack, I know, but...
                else {
                    process_subneg(telnet);
                    receiveState = kStateStart;
                }
                break;
        */
        }
    }
    
    [(NSObject *)_displayDelegate performSelectorOnMainThread:@selector(displayData:) withObject:dataForDisplay waitUntilDone:NO];
    
    dataForDisplay = nil;
    // look for more
    [sock readDataWithTimeout:-1 tag:readSequence++];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error {
    
    NSLog(@"Disconnect received");
}
// GCDAsyncSocket delegate ends

@end
