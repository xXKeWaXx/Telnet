//
//  TelnetOptionTerminalType.m
//  Telnet
//
//  Created by Adam Eberbach on 29/08/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TelnetOptionTerminalType.h"

@implementation TelnetOptionTerminalType

- (NSData *)processSB:(NSData *)dataForSubnegotiation {
    
    unsigned char *c = [(NSMutableData *)dataForSubnegotiation mutableBytes];
    
    if(*c == kTelnetSubnegotiationSEND) {
        
        unsigned char subnegotiationStartBuf[4];
        *(subnegotiationStartBuf + 0) = kTelnetCharIAC;
        *(subnegotiationStartBuf + 1) = kTelnetCharSB;
        *(subnegotiationStartBuf + 2) = kTelnetOptionTerminalType;
        *(subnegotiationStartBuf + 3) = kTelnetSubnegotiationIS;
        
        char* termType = "DEC-VT220";
        unsigned char subnegotiationEndBuf[2];
        *(subnegotiationEndBuf + 0) = kTelnetCharIAC;
        *(subnegotiationEndBuf + 1) = kTelnetCharSE;
        
        NSMutableData *subnegotiationMessage = [NSMutableData data];
        [subnegotiationMessage appendBytes:subnegotiationStartBuf length:4];
        [subnegotiationMessage appendBytes:termType length:strlen(termType)];
        [subnegotiationMessage appendBytes:subnegotiationEndBuf length:2];
        
        return subnegotiationMessage;
        
    } else
        return nil;
}

@end
