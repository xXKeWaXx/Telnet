//
//  Parser.m
//  xterminal
//
//  Created by Adam Eberbach on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
//
// Parser gets each chunk of data from the network and breaks it up, passing each atom
// of data that can be acted upon to the terminal

#import "Parser.h"

typedef enum _TerminalDataState {
    kStateGround,
    kStateEsc,
    kStateEscIntermediate,
    kStateCSIEntry,
    kStateCSIParam,
    kStateCSIIntermediate,
    kStateCSIIgnore,
    kStateDCSEntry,
    kStateDCSParam,
    kStateDCSIntermediate,
    kStateDCSPassthrough,
    kStateDCSIgnore,
    kStateOSCString,
    kStateSOSPMAPCString
    
} TerminalDataState;

@interface Parser (private)
- (BOOL)isControlChar:(uint8_t)c;
- (BOOL)isPrintableChar:(uint8_t)c;
- (TerminalDataState)stateNow:(TerminalDataState)now withChar:(uint8_t)c;
- (void)processAtoms;
@end

@implementation Parser

@synthesize terminalDelegate;

#pragma mark -
#pragma mark ParserDelegate

// display each of the bytes in the view advancing cursor position
- (void)parseData:(NSData *)data {
    
    if(incomingData == nil) {
        incomingData = [data mutableCopy];
    } else {
        [incomingData appendData:data];
    }
    
    [self performSelectorOnMainThread:@selector(processAtoms) 
                           withObject:nil 
                        waitUntilDone:YES];
}

// new connection, reset everything
- (void)connectionMade {
    [terminalDelegate reset];
}


#pragma mark -
#pragma mark Parser

- (BOOL)isControlChar:(uint8_t)c {
    if ((c >= 0x00 && c <= 0x17) ||
        (c == 0x19) ||
        (c >= 0x1c && c <= 0x1f))
        return YES;
    return NO;
}

- (BOOL)isPrintableChar:(uint8_t)c {
    if(c >= 0x20 && c <= 0x7f)
        return YES;
    return NO;
}

- (TerminalDataState)stateNow:(TerminalDataState)now withChar:(uint8_t)c {

    TerminalDataState takeState = now;
    
    if(c == 0x1b) {
        takeState = kStateEsc;
    } else if ((c == 0x18 || c == 0x1A) || (c >= 0x80 && c <= 0x8f) ||
               (c >= 0x91 && c <= 0x97) || (c == 0x9a) || (c == 0x9c)) {
        takeState = kStateGround;
    } else if (c == 0x9b) {
        takeState = kStateCSIEntry;
    } else if (c == 0x98 || c == 0x9e || c == 0x9f) {
        takeState = kStateSOSPMAPCString;
    } else if(c == 0x9d) {
        takeState = kStateOSCString;
    } else if(c == 0x90) {
        takeState = kStateDCSEntry;
    }
    return takeState;
}

- (void)processAtoms {
    
    unsigned char *c = (unsigned char *)[incomingData bytes];
    int len = [incomingData length];
    
    TerminalDataState state = kStateGround;
    TerminalDataState transitionState;
    NSMutableData *param = [NSMutableData data];
    
    while(len--) {
        uint8_t d = *c++;
        // some transitions can happen from "anywhere"
        if((transitionState = [self stateNow:state withChar:d]) != state) {
            
            if(transitionState == kStateEsc ||
               transitionState == kStateDCSEntry ||
               transitionState == kStateCSIEntry) {

                param = [NSMutableData data];
                [param appendBytes:&d length:1];
            }
            state = transitionState;
            continue;
        }
        
        switch(state) {
            case kStateGround:
                if([self isPrintableChar:d]) { 
                    [terminalDelegate characterDisplay:d];
                } else if([self isControlChar:d] == YES) { 
                    [terminalDelegate characterNonDisplay:d];
                }
                break;
            case kStateEsc:
                if([self isControlChar:d] == YES) {
                    [terminalDelegate characterNonDisplay:d];
                } else if(d == 0x50) {
                    param = [NSMutableData data];
                    state = kStateDCSEntry;
                } else if(d == 0x58 || d == 0x5e || d == 0x5f) {
                    state = kStateSOSPMAPCString;
                } else if(d == '[') {
                    [param appendBytes:&d length:1];
                    state = kStateCSIEntry;
                } else if(d == 0x5d) {
                    // sction osc_start TODO
                    state = kStateOSCString;
                } else if((d >= 0x30 && d <= 0x4f) || (d >= 0x51 && d <= 0x57) ||
                          d == 0x59 || d == 0x5a || d == 0x5c || (d >= 0x60 && d <= 0x7e)) {
                    [param appendBytes:&d length:1];
                    [terminalDelegate processCommand:param];
                    param = [NSMutableData data];
                    state = kStateGround;
                } else if(d >= 0x20 && d <= 0x2f) {
                    [param appendBytes:&d length:1];
                    state = kStateEscIntermediate;
                } // ignore 0x7f
                break;
            case kStateEscIntermediate:
                if([self isControlChar:d] == YES) {
                    [terminalDelegate characterNonDisplay:d];
                } else if(d >= 0x20 && d <= 0x2f) {
                    [param appendBytes:&d length:1];
                } else if(d >= 0x30 && d <= 0x7e) {
                    [param appendBytes:&d length:1];
                    [terminalDelegate processCommand:param];
                    param = [NSMutableData data];
                    state = kStateGround;
                } // ignore 0x7f
                break;
            case kStateCSIEntry:
                if([self isControlChar:d] == YES) {
                    [terminalDelegate characterNonDisplay:d];
                } else if(d >= 0x40 && d <= 0x7e) {
                    [param appendBytes:&d length:1];
                    [terminalDelegate processCommand:param];
                    param = [NSMutableData data];
                    state = kStateGround;
                } else if((d >= 0x30 && d <= 0x39) ||
                          d == 0x3b) {
                    [param appendBytes:&d length:1];
                    state = kStateCSIParam;
                } else if(d >= 0x3c && d <= 0x3f) {
                    [param appendBytes:&d length:1];
                    state = kStateCSIParam;
                } else if(d >= 0x20 && d <= 0x2f) {
                    [param appendBytes:&d length:1];
                    state = kStateCSIIntermediate;
                } else if(d >= 0x3a) {
                    state = kStateCSIIgnore;
                } // ignore 0x7f
                break;
            case kStateCSIParam:
                if([self isControlChar:d] == YES) {
                    [terminalDelegate characterNonDisplay:d];
                } else if((d >= 0x30 && d <= 0x39) ||
                          d == 0x3b) {
                    [param appendBytes:&d length:1];
                } else if(d >= 0x40 && d <= 0x7e) {
                    [param appendBytes:&d length:1];
                    [terminalDelegate processCommand:param];
                    param = [NSMutableData data];
                    state = kStateGround;
                } else if((d >= 0x3c && d <= 0x3f) ||
                          d == 0x3a) {
                    state = kStateCSIIgnore;
                }
                break;
            case kStateCSIIntermediate:
                if([self isControlChar:d] == YES) {
                    [terminalDelegate characterNonDisplay:d];
                } else if(d >= 0x20 && d <= 0x2f) {
                    [param appendBytes:&d length:1];
                } else if(d >= 0x30 && d <= 0x3f) {
                    state = kStateCSIIgnore;
                } else if(d >= 0x40 && d <= 0x7e) {
                    [param appendBytes:&d length:1];
                    [terminalDelegate processCommand:param];
                    param = [NSMutableData data];
                    state = kStateGround;
                } // ignore 0x7f
                break;
            case kStateCSIIgnore:
                if([self isControlChar:d] == YES) {
                    [terminalDelegate characterNonDisplay:d];
                } else if(d >= 0x40 && d <= 0x7e) {
                    state = kStateGround;
                } // ignore 0x20-0x3f and 0x7f
                break;
            case kStateDCSEntry:
                // ignore control chars here
                if(d >= 0x20 && d <= 0x2f) {
                    [param appendBytes:&d length:1];
                    state = kStateDCSIntermediate;
                } else if(d == 0x3a) {
                    state = kStateDCSIgnore;
                } else if((d >= 0x30 && d <= 0x39) ||
                          d == 0x3b) {
                    [param appendBytes:&d length:1];
                    state = kStateDCSParam;
                } else if(d >= 0x3c && d <= 0x3f) {
                    [param appendBytes:&d length:1];
                    state = kStateDCSParam;
                } else if(d >= 0x40 && d <= 0x7e) {
                    // action hook TODO
                    state = kStateDCSPassthrough;
                } // ignore 0x7f
                break;
            case kStateDCSParam:
                // ignore control chars here
                if((d >= 0x30 && d <= 0x39) || d == 0x3b) {
                    // action param TODO
                } else if((d >= 0x3c && d <= 0x3f) || d == 0x3a) {
                    // action param TODO
                    state = kStateDCSIgnore;
                } else if(d >= 0x40 && d <= 0x7e) {
                    // action hook TODO
                    state = kStateDCSPassthrough;
                } else if(d >= 0x20 && d <= 0x2f) {
                    // action collect TODO
                    state = kStateDCSIntermediate;
                } // ignore 0x7f
                break;
            case kStateDCSIntermediate:
                // ignore control chars here
                if(d >= 0x20 && d <= 0x2f) {
                    // action collect TODO
                } else if(d >= 0x30 && d <= 0x3f) {
                    state = kStateDCSIgnore;
                } else if(d >= 0x40 && d <= 0x7e) {
                    // action hook TODO
                    state = kStateDCSPassthrough;
                } // ignore 0x7f
                break;
            case kStateDCSPassthrough:
                if((d >= 0x00 && d <= 0x17) ||
                   d == 0x19 ||
                   (d >= 0x1c && d <= 0x1f) ||
                   (d >= 0x20 && d <= 0x7e)) {
                    // action put to hook TODO
                } else if(d == 0x9c) {
                    // action unhook TODO
                    state = kStateGround;
                }
                break;
            case kStateDCSIgnore:
                if(d == 0x9c)
                    state = kStateGround;
                break;
            case kStateOSCString:
                if(d >= 0x20 && d <= 0x7f) {
                    // action osc_put TODO
                } else if(d == 0x9c) {
                    // action osc_end TODO
                    state = kStateGround;
                }
                break;
            case kStateSOSPMAPCString:
                if(d == 0x9c) {
                    state = kStateGround;
                }
                break;
        }
    }
    
    if([param length] > 0) {
        // a command is still being received, save and append the rest as it appears
        incomingData = param;
    } else {
        incomingData = nil;
    }
}

@end
