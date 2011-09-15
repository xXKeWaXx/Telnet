//
//  TelnetConnection.m
//  Telnet
//
//  Created by Adam Eberbach on 20/08/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TelnetConnection.h"

@implementation TelnetConnection

@synthesize identityDelegate = _identityDelegate;

- (id)init {
    
    self = [super init];
    if(self) {
     
        readSequence = writeSequence = 0;
        inSynch = NO;
        receiveState = kStateStart;
        
        optionHandlers = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setOptions:(NSData *)jsonOptions {
    
    NSString *file = [[NSBundle mainBundle] pathForResource:@"TelnetOptions" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:file];
    NSDictionary *dict2 = [dict objectForKey:kTelnetOptionsArray];
    NSArray *optionsArray = [dict2 objectForKey:kTelnetOptionsArray];

    Class handlerClass;
    
    for(NSDictionary *optionsDictionary in optionsArray) {

        handlerClass = NSClassFromString([optionsDictionary objectForKey:kTelnetOptionClassname]);
        TelnetOptionHandler *optionHandler = [[handlerClass alloc] init];
        optionHandler.acceptsOption = [[optionsDictionary objectForKey:kTelnetOptionSupported] boolValue];
        [optionHandlers setObject:optionHandler forKey:[optionsDictionary objectForKey:kTelnetOptionNumber]];
    }
}

- (void)open:(NSString *)hostName port:(unsigned long)port {
    
    socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *error;
    [socket connectToHost:hostName onPort:port error:&error];

    NSData *display = [NSData dataWithBytes:kTelnetMsgConnecting length:strlen(kTelnetMsgConnecting)];
    [_identityDelegate displayData:display];
}

#define SEND_BUFSIZE (600)

- (void)read {
    [socket readDataWithTimeout:-1 tag:readSequence++];

}

- (void)sendData:(NSData *)sendData {

    [socket writeData:sendData withTimeout:-1 tag:writeSequence++];
}

- (void)sendString:(NSString *)sendString {
    
    const char *buf = [sendString cStringUsingEncoding:NSASCIIStringEncoding];
    NSData *data = [[NSData alloc] initWithBytes:buf length:[sendString length]];
    
    [self sendData:data];
}

- (void)sendOption:(unsigned char)option command:(unsigned char)cmd {
    
    unsigned char commandBuf[3];
    *(commandBuf + 0) = kTelnetCharIAC;
    *(commandBuf + 1) = cmd;
    *(commandBuf + 2) = option;
    
    NSData *optionData = [[NSData alloc] initWithBytes:commandBuf length:3];
    [socket writeData:optionData withTimeout:-1 tag:writeSequence++];
}

- (void)processReceivedOption:(unsigned char)option command:(unsigned char)cmd {
    
    // look for option handler in our option handler dict
    TelnetOptionHandler *optionHandler = [optionHandlers objectForKey:[NSNumber numberWithInt:option]];
          
    if(optionHandler)
        NSLog(@"option handler exists for option %d", option);
    
    if(cmd == kTelnetCharWILL) {
        if(optionHandler && [optionHandler acceptsOption]) {
            [self sendOption:option command:kTelnetCharDO];
            NSLog(@"Responded DO for option %d", option);
        } else {
            [self sendOption:option command:kTelnetCharDONT];
        }
    } else if(cmd == kTelnetCharDO) {
        if(optionHandler && [optionHandler acceptsOption]) {
            [self sendOption:option command:kTelnetCharWILL];
            NSLog(@"Responded WILL for option %d", option);
        } else {
            [self sendOption:option command:kTelnetCharWONT];
        }
    }
}

- (void)processSubnegotiation {
    
    switch(subnegotiationType) {

        case kTelnetOptionTerminalType:
        {
            
#define kTelnetSubnegotiationSEND (1)
#define kTelnetSubnegotiationIS (0)
            
            unsigned char *c = [dataForSubnegotiation mutableBytes];
            
            if(subnegotiationType == 1 && *c == kTelnetSubnegotiationSEND) {
                
                unsigned char subnegotiationStartBuf[4];
                *(subnegotiationStartBuf + 0) = kTelnetCharIAC;
                *(subnegotiationStartBuf + 1) = kTelnetCharSB;
                *(subnegotiationStartBuf + 2) = kTelnetOptionTerminalType;
                *(subnegotiationStartBuf + 3) = kTelnetSubnegotiationIS;
                
                char* termType = "DEC-VT220";
                unsigned char subnegotiationEndBuf[2];
                *(subnegotiationEndBuf + 0) = kTelnetCharIAC;
                *(subnegotiationEndBuf + 1) = kTelnetCharSE;

                NSMutableData *subnegotiationMessage = [NSMutableData dataWithCapacity:10];
                [subnegotiationMessage appendBytes:subnegotiationStartBuf length:4];
                [subnegotiationMessage appendBytes:termType length:strlen(termType)];
                [subnegotiationMessage appendBytes:subnegotiationEndBuf length:2];
                
                [socket writeData:subnegotiationMessage withTimeout:-1 tag:writeSequence++];
            }
            break;
        }
        default:
            break;
    }    
    /*
    static void process_subneg(Telnet telnet)
    {
        unsigned char b[2048], *p, *q;
        int var, value, n;
        char *e;
        
        switch (telnet->sb_opt) {
            case TELOPT_TSPEED:
                if (telnet->sb_len == 1 && telnet->sb_buf[0] == TELQUAL_SEND) {
                    char *logbuf;
                    b[0] = IAC;
                    b[1] = SB;
                    b[2] = TELOPT_TSPEED;
                    b[3] = TELQUAL_IS;
                    strcpy((char *)(b + 4), telnet->cfg.termspeed);
                    n = 4 + strlen(telnet->cfg.termspeed);
                    b[n] = IAC;
                    b[n + 1] = SE;
                    telnet->bufsize = sk_write(telnet->s, (char *)b, n + 2);
                    logevent(telnet->frontend, "server:\tSB TSPEED SEND");
                    logbuf = dupprintf("client:\tSB TSPEED IS %s", telnet->cfg.termspeed);
                    logevent(telnet->frontend, logbuf);
                    sfree(logbuf);
                } else
                    logevent(telnet->frontend, "server:\tSB TSPEED <something weird>");
                break;
            case TELOPT_TTYPE:
                if (telnet->sb_len == 1 && telnet->sb_buf[0] == TELQUAL_SEND) {
                    char *logbuf;
                    b[0] = IAC;
                    b[1] = SB;
                    b[2] = TELOPT_TTYPE;
                    b[3] = TELQUAL_IS;
                    for (n = 0; telnet->cfg.termtype[n]; n++)
                        b[n + 4] = (telnet->cfg.termtype[n] >= 'a'
                                    && telnet->cfg.termtype[n] <=
                                    'z' ? telnet->cfg.termtype[n] + 'A' -
                                    'a' : telnet->cfg.termtype[n]);
                    b[n + 4] = IAC;
                    b[n + 5] = SE;
                    telnet->bufsize = sk_write(telnet->s, (char *)b, n + 6);
                    b[n + 4] = 0;
                    logevent(telnet->frontend, "server:\tSB TTYPE SEND");
                    logbuf = dupprintf("client:\tSB TTYPE IS %s", b + 4);
                    logevent(telnet->frontend, logbuf);
                    sfree(logbuf);
                } else
                    logevent(telnet->frontend, "server:\tSB TTYPE <something weird>\r\n");
                break;
            case TELOPT_OLD_ENVIRON:
            case TELOPT_NEW_ENVIRON:
                p = telnet->sb_buf;
                q = p + telnet->sb_len;
                if (p < q && *p == TELQUAL_SEND) {
                    char *logbuf;
                    p++;
                    logbuf = dupprintf("server:\tSB %s SEND", telopt(telnet->sb_opt));
                    logevent(telnet->frontend, logbuf);
                    sfree(logbuf);
                    if (telnet->sb_opt == TELOPT_OLD_ENVIRON) {
                        if (telnet->cfg.rfc_environ) {
                            value = RFC_VALUE;
                            var = RFC_VAR;
                        } else {
                            value = BSD_VALUE;
                            var = BSD_VAR;
                        }
                         // Try to guess the sense of VAR and VALUE.
                        while (p < q) {
                            if (*p == RFC_VAR) {
                                value = RFC_VALUE;
                                var = RFC_VAR;
                            } else if (*p == BSD_VAR) {
                                value = BSD_VALUE;
                                var = BSD_VAR;
                            }
                            p++;
                        }
                    } else {
                         // With NEW_ENVIRON, the sense of VAR and VALUE
                         // isn't in doubt.

                        value = RFC_VALUE;
                        var = RFC_VAR;
                    }
                    b[0] = IAC;
                    b[1] = SB;
                    b[2] = telnet->sb_opt;
                    b[3] = TELQUAL_IS;
                    n = 4;
                    e = telnet->cfg.environmt;
                    while (*e) {
                        b[n++] = var;
                        while (*e && *e != '\t')
                            b[n++] = *e++;
                        if (*e == '\t')
                            e++;
                        b[n++] = value;
                        while (*e)
                            b[n++] = *e++;
                        e++;
                    }
                    {
                        char user[sizeof(telnet->cfg.username)];
                        (void) get_remote_username(&telnet->cfg, user, sizeof(user));
                        if (*user) {
                            b[n++] = var;
                            b[n++] = 'U';
                            b[n++] = 'S';
                            b[n++] = 'E';
                            b[n++] = 'R';
                            b[n++] = value;
                            e = user;
                            while (*e)
                                b[n++] = *e++;
                        }
                        b[n++] = IAC;
                        b[n++] = SE;
                        telnet->bufsize = sk_write(telnet->s, (char *)b, n);
                        logbuf = dupprintf("client:\tSB %s IS %s%s%s%s",
                                           telopt(telnet->sb_opt),
                                           *user ? "USER=" : "",
                                           user,
                                           *user ? " " : "",
                                           n == 6 ? "<nothing>" :
                                           (*telnet->cfg.environmt ? "<stuff>" : ""));
                        logevent(telnet->frontend, logbuf);
                        sfree(logbuf);
                    }
                }
                break;
        }
    }
*/
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
    if(dataForSubnegotiation == nil)
        dataForSubnegotiation = [[NSMutableData alloc] init];
    
    // data is NSData not NSMutableData, bytes cannot actually be modified through buf, the cast hides a warning
    char *buf = (char *)[data bytes];
    int len = [data length];

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
                [self processReceivedOption:c command:kTelnetCharWILL];
                receiveState = kStateStart;
                break;
            case kStateSeenWONT:
                [self processReceivedOption:c command:kTelnetCharWONT];
                receiveState = kStateStart;
                break;
            case kStateSeenDO:
                [self processReceivedOption:c command:kTelnetCharDO];
                receiveState = kStateStart;
                break;
            case kStateSeenDONT:
                [self processReceivedOption:c command:kTelnetCharDONT];
                receiveState = kStateStart;
                break;
            case kStateSeenSB:
                subnegotiationType = c;
                subnegotiationLen = 0;
                receiveState = kStateSubnegotiating;
                break;
            case kStateSubnegotiating:
                if(c == kTelnetCharIAC)
                    receiveState = kStateSubnegotiatingSeenIAC;
                else 
                    [dataForSubnegotiation appendBytes:&c length:1];
                break;
            case kStateSubnegotiatingSeenIAC:
                if (c != kTelnetCharSE) {
                    [dataForSubnegotiation appendBytes:&c length:1];
                    receiveState = kStateSubnegotiating;
                } else {
                    // subnegotiation argument finished, process using handler matching subnegotiationType
                    TelnetOptionHandler *optionHandler = [optionHandlers objectForKey:[NSNumber numberWithInt:subnegotiationType]];
                    if([optionHandler respondsToSelector:@selector(processSB:)]) {

                        // return handler's response to subnegotiation
                        NSData *subnegotiationResponse = [optionHandler performSelector:@selector(processSB:) withObject:dataForSubnegotiation];
                        [socket writeData:subnegotiationResponse withTimeout:-1 tag:writeSequence++];
                    }
                    dataForSubnegotiation = [[NSMutableData alloc] init];
                    receiveState = kStateStart;
                }
                break;                
        }
    }
    
    [(NSObject *)_identityDelegate performSelectorOnMainThread:@selector(displayData:) withObject:dataForDisplay waitUntilDone:NO];
    
    dataForDisplay = nil;

    // look for more
    [sock readDataWithTimeout:-1 tag:readSequence++];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error {
    
    NSLog(@"Disconnect received");
}
// GCDAsyncSocket delegate ends

@end
