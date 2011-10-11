//
//  Terminal.m
//  xterminal
//
//  Created by Adam Eberbach on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Terminal.h"

@implementation Terminal

@synthesize displayDelegate;

- (void)logCommand:(NSMutableData *)data {
    
    int len = [data length];
    NSMutableString *dataString = [NSMutableString stringWithCapacity:len];
    
    unsigned char *c = [data mutableBytes];
    while(len--) {
        unsigned char d = *c++;
        if(d == 0x1b) {
            [dataString appendFormat:@"%@", @"ESC"];
        } else {
            [dataString appendFormat:@"%c", d];
        }
    }
    NSLog(@"command: %@", dataString);
}

#pragma mark -
#pragma mark TerminalDelegate

- (void)characterDisplay:(unsigned char)c {
    NSLog(@"display %c", c);
}

- (void)characterNonDisplay:(unsigned char)c {
    switch(c) {
        case kTelnetCharCR:
            NSLog(@"CR");
            break;
        case kTelnetCharFF:
        case kTelnetCharVT:
            NSLog(@"FF/VT");
            break;
        case kTelnetCharLF:
            NSLog(@"LF");
            break;
        case kTelnetCharHT:            
            NSLog(@"HT");
            break;
        case kTelnetCharBS:            
            NSLog(@"BS");
            break;
        case kTelnetCharBEL:
            NSLog(@"ding!");
            break;
        case kTelnetCharNUL:
            NSLog(@"NUL");
        default:
            break;
    }
}

- (void)processCommand:(NSData *)command {
    [self logCommand:command];
}

@end
