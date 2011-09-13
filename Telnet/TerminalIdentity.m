
//
//  TerminalIdentity.m
//  xterminal
//
//  Created by Adam Eberbach on 10/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TerminalIdentity.h"
#import "TelnetConstants.h"

@implementation TerminalIdentity

@synthesize displayDelegate = _displayDelegate;

- (BOOL)isTelnetControl:(unsigned char)c {

    if(c == 000     // NUL
       || c == 005  // ENQ
       || c == 007  // BEL
       || c == 010  // BS
       || c == 011  // HT
       || c == 012  // LF
       || c == 013  // VT
       || c == 014  // FF
       || c == 015) // CR
        return YES;
    return NO;
}
- (BOOL)isTelnetPrintable:(unsigned char)c {

    if(c >= 32 && c <= 126)
        return YES;
    return NO;
}

- (BOOL)recognisedCommand:(NSString *)commandIdentifier withNumerics:(NSMutableArray *)numericValues {
    
    BOOL handled = NO;
    int commandValue;
    
    do{
        if([numericValues count] == 0) {
            commandValue = 0;
        } else {
            commandValue = [[numericValues objectAtIndex:0] intValue];
        }
        
        if([commandIdentifier isEqualToString:@"l"]) {
            if([numericValues count] > 0)
                [numericValues removeObjectAtIndex:0];
            handled = YES;
        } else if([commandIdentifier isEqualToString:@"m"]) {
            [_displayDelegate displayReset];
            handled = YES;
        } else if([commandIdentifier isEqualToString:@"r"]) {
            int firstRow, lastRow;
            
            if([numericValues count] == 0) {
                firstRow = 1;
                lastRow = 24;
            } else {
                firstRow = [[numericValues objectAtIndex:0] intValue];
                lastRow = [[numericValues objectAtIndex:1] intValue];
            }
            [_displayDelegate terminalWindowSetRowStart:firstRow rowEnd:lastRow];
            [numericValues removeAllObjects];
            handled = YES;
        } else if([commandIdentifier isEqualToString:@"A"]) {
            while(commandValue--)
                [_displayDelegate cursorUp];
            if([numericValues count] > 0)
                [numericValues removeObjectAtIndex:0];
            handled = YES;
        } else if([commandIdentifier isEqualToString:@"B"]) {
            while(commandValue--)
                [_displayDelegate cursorDown];
            if([numericValues count] > 0)
                [numericValues removeObjectAtIndex:0];
            handled = YES;
        } else if([commandIdentifier isEqualToString:@"C"]) {
            while(commandValue--)
                [_displayDelegate cursorRight];
            if([numericValues count] > 0)
                [numericValues removeObjectAtIndex:0];
            handled = YES;
        } else if([commandIdentifier isEqualToString:@"D"]) {
            while(commandValue--)
                [_displayDelegate cursorLeft];
            if([numericValues count] > 0)
                [numericValues removeObjectAtIndex:0];
            handled = YES;
        } else if([commandIdentifier isEqualToString:@"H"]) {
            int row, col;
            row = [[numericValues objectAtIndex:0] intValue];
            col = [[numericValues objectAtIndex:1] intValue];
            [_displayDelegate cursorSetRow:row column:col];
            [numericValues removeAllObjects];
            handled = YES;
        } else if([commandIdentifier isEqualToString:@"K"]) {
            switch(commandValue) {
                case 0: // clear from cursor to end of line
                    [_displayDelegate clearCursorRight];
                    break;
                case 1: // clear from beginning of line to cursor
                    [_displayDelegate clearCursorLeft];
                    break;
                default:
                    [_displayDelegate clearRow];
                    break;
            }
            if([numericValues count] > 0)
                [numericValues removeObjectAtIndex:0];
            handled = YES;

        }
    } while(0); //[numericValues count] != 0);

    return handled;
}

// ANSI command 'J'
- (void)commandEraseScreen:(unsigned char)argument {
    switch(argument) {
        case 0: // clear from cursor to end of screen
            [_displayDelegate clearCursorBelow];
            break;
        case 1: // clear from beginning of screen to cursor
            [_displayDelegate clearCursorAbove];
            break;
        default: // clear all
            [_displayDelegate clearAll];
    }
}

// ANSI command 'K'
- (void)commandEraseLine:(unsigned char)argument {
    switch(argument) {
        case 0: // clear from cursor to end of line
            [_displayDelegate clearCursorRight];
            break;
        case 1: // clear from beginning of line to cursor
            [_displayDelegate clearCursorLeft];
            break;
        default:
            [_displayDelegate clearRow];
            break;
    }
}

#define COMMAND_DEFAULT_VALUE (255)

// for extracting single, simple values
- (int)parseSimpleNumeric:(unsigned char *)sequence length:(int)len {

    unsigned char thisChar;
    int numeric = 0;
    
    if(len == 0) {
        numeric = COMMAND_DEFAULT_VALUE;
    } else {
        while(len--) {
            thisChar = *(sequence + len);
            numeric *= 10;
            numeric += thisChar - '0';
        }
    }
    return numeric;
}

// iterate over the values represented by the chars in sequence, extracting numeric values
- (NSMutableData *)parseNumerics:(unsigned char *)sequence length:(int)len {

    NSMutableData *numericSequence = [NSMutableData data];
    unsigned char thisChar;
    unsigned char numeric = 0;
    BOOL isFirstChar = YES;
    BOOL inNumericSequence = NO;
    static const unsigned char defaultValue = COMMAND_DEFAULT_VALUE;
        
    while(len--) {
        thisChar = *(sequence + len);
        
        if(isFirstChar == YES) {
            if(thisChar == ';') {
                // a ';' first up indicates a default value
                [numericSequence appendBytes:&defaultValue length:1];
            } else {
                numeric = thisChar - '0';
                inNumericSequence = YES;
            }
            isFirstChar = NO;
        } else {
            if(thisChar == ';') {
                [numericSequence appendBytes:&numeric length:1];
                numeric = 0;
                inNumericSequence = NO;
            } else {
                numeric *= 10;
                numeric += thisChar - '0';
                inNumericSequence = YES;
            }
        }
    }
    if(inNumericSequence == YES)
        // final value must be added
        [numericSequence appendBytes:&numeric length:1];
    else 
        // a trailing ; also indicates a default value
        [numericSequence appendBytes:&defaultValue length:1];
    
    return numericSequence;
}

// command sequence comes in reverse to make processing easier
- (void)processANSICommandSequence:(unsigned char *)sequence withLength:(int)len {
    
    unsigned char finalChar = *sequence;
    // finalChar is the first char, advance
    len--; 
    sequence++;
    int count; 
    
    switch(finalChar) {
        case 'A': // cursor up
        {
            count = [self parseSimpleNumeric:sequence length:len];
            if(count == COMMAND_DEFAULT_VALUE)
                count = 1;
            while(count--)
                [_displayDelegate cursorUp];
        }
            break;
        case 'B': // cursor down
        {
            count = [self parseSimpleNumeric:sequence length:len];
            if(count == COMMAND_DEFAULT_VALUE)
                count = 1;
            while(count--)
                [_displayDelegate cursorDown];
        }
            break;
        case 'C': // cursor forward (right)
        {
            count = [self parseSimpleNumeric:sequence length:len];
            if(count == COMMAND_DEFAULT_VALUE)
                count = 1;
            while(count--)
                [_displayDelegate cursorRight];
        }
            break;
        case 'D': // cursor backward (left)
        {
            count = [self parseSimpleNumeric:sequence length:len];
            if(count == COMMAND_DEFAULT_VALUE)
                count = 1;
            while(count--)
                [_displayDelegate cursorLeft];
        }
            break;
        case 'J':
        {
            switch(len) {
                case 0: // default erase to end of screen
                    [self commandEraseScreen:'0'];
                    break;
                case 1: 
                    [self commandEraseScreen:*sequence];
                    break;
            }
        }
            break;
        case 'K':
            switch(len) {
                case 0: // default erase to end of screen
                    [self commandEraseLine:'0'];
                    break;
                case 1: 
                    [self commandEraseLine:*sequence];
                    break;
            }
            break;
        case 'H':
        case 'f':
        {
            NSMutableData *orderedNumerics = [self parseNumerics:sequence length:len];
            unsigned char *bytes = [orderedNumerics mutableBytes];
            if(*bytes > 24 || *(bytes + 1) > 80)
                NSLog(@"Dodgy cursor position!");
            else
                [_displayDelegate cursorSetRow:*bytes column:*(bytes + 1)];
            
        }
            break;
        default:
            NSLog(@"Unhandled command sequence finalChar %c", finalChar);
    }
    
}

- (void)processDECCommandSequence:(unsigned char *)sequence withLength:(int)len {
    NSString *commandDebugString = [NSString string];
    
    while(len--) {
        commandDebugString = [commandDebugString stringByAppendingFormat:@"%c", *sequence++];
    }
}

- (void)processCommandSequence:(NSData *)sequence {

    unsigned char * c = (unsigned char *)[sequence bytes];
    int len = [sequence length];
    NSMutableData *reversedCommand = [NSMutableData data];
    BOOL isANSI = NO;
    
    int reverseLen = len;
    
    while(reverseLen) {
    
        unsigned char thisChar = *(c + --reverseLen);
        
        if(thisChar != 033) {
            if(thisChar == '[') {
                isANSI = YES;
            } else {
                [reversedCommand appendBytes:&thisChar length:1];
            }
        }
    }

    if(isANSI == YES) {
        [self processANSICommandSequence:[reversedCommand mutableBytes] withLength:[reversedCommand length]];
    } else {
        [self processDECCommandSequence:[reversedCommand mutableBytes] withLength:[reversedCommand length]];
    }
}

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

BOOL isControlChar(uint8_t character);
TerminalDataState transitionFromAnywhere(uint8_t character, int stateNow);

BOOL isControlChar(uint8_t character) {
    if ((character > 0x00 && character < 0x17) ||
        (character == 0x19) ||
        (character >= 0x1c && character <= 0x1f))
        return YES;
    return NO;
}

TerminalDataState transitionFromAnywhere(uint8_t character, int stateNow) {

    TerminalDataState takeState;
    
    if(character == 0x1b) {
        takeState = kStateEsc;
    } else if ((character == 0x18 || character == 0x1A) ||
               (character >= 0x80 && character <= 0x8f) ||
               (character >= 0x91 && character <= 0x97) ||
               (character == 0x9a) ||
               (character == 0x9c)) {
        takeState = kStateGround;
    } else if (character == 0x9b) {
        takeState = kStateCSIEntry;
    } else if (character == 0x98 ||
               character == 0x9e ||
               character == 0x9f) {
        takeState = kStateSOSPMAPCString;
    } else if(character == 0x9d) {
        takeState = kStateOSCString;
    } else if(character == 0x90) {
        takeState = kStateDCSEntry;
    } else {
        takeState = stateNow;
    }
    return takeState;
}

- (void)processDataChunk {
    
    unsigned char *c = (unsigned char *)[dataForDisplay bytes];
    int len = [dataForDisplay length];
    TerminalDataState state;
    TerminalDataState transitionState;
//    privateFlag;
//    intermediateCharacters;
//    finalCharacter;
//    parameters;
    
    while(len--) {
        uint8_t d = *c++;
        // some transitions can happen from "anywhere"
        if((transitionState = transitionFromAnywhere(d, state)) != state) {
            if(transitionState == kStateEsc ||
               transitionState == kStateDCSEntry ||
               transitionState == kStateCSIEntry) {
                // on entry, clear 
                //    privateFlag;
                //    intermediateCharacters;
                //    finalCharacter;
                //    parameters;
            }
            state = transitionState;
            continue;
        }
        
        switch(state) {
            case kStateGround:
                if(d > 0x20 && d < 0x7f) { 
                    // display printable chars
                    [_displayDelegate characterDisplay:d];
                } else if(isControlChar(d) == YES) { 
                    [_displayDelegate characterNonDisplay:d];
                }
                break;
            case kStateEsc:
                if(isControlChar(d) == YES) {
                    [_displayDelegate characterNonDisplay:d];
                } else if(d == 0x50) {
                    // on entry, clear 
                    //    privateFlag;
                    //    intermediateCharacters;
                    //    finalCharacter;
                    //    parameters;
                    state = kStateDCSEntry;
                } else if(d == 0x58 ||
                          d == 0x5e ||
                          d == 0x5f) {
                    state = kStateSOSPMAPCString;
                } else if(d == 0x5b) {
                    // on entry, clear 
                    //    privateFlag;
                    //    intermediateCharacters;
                    //    finalCharacter;
                    //    parameters;
                    state = kStateCSIEntry;
                } else if(d == 0x5d) {
                    // sction osc_start TODO
                    state = kStateOSCString;
                } else if((d >= 0x30 && d <= 0x4f) ||
                          (d >= 0x51 && d <= 0x57) ||
                          d == 0x59 ||
                          d == 0x5a ||
                          d == 0x5c ||
                          (d >= 0x60 && d < 0x7e)) {
                    // action esc_dispatch TODO
                    state = kStateGround;
                } else if(d >= 0x20 && d <= 0x2f) {
                    // action collect TODO
                    state = kStateEscIntermediate;
                } // ignore 0x7f
                break;
            case kStateEscIntermediate:
                if(isControlChar(d) == YES) {
                    [_displayDelegate characterNonDisplay:d];
                } else if(d >= 0x20 && d <= 0x2f) {
                    // action collect TODO
                } else if(d >= 0x30 && d <= 0x7e) {
                    // action esc_dispatch TODO
                    state = kStateGround;
                } // ignore 0x7f
                break;
            case kStateCSIEntry:
                if(isControlChar(d) == YES) {
                    [_displayDelegate characterNonDisplay:d];
                } else if(d >= 0x40 || d <= 0x7e) {
                    // action csi_dispatch TODO
                    state = kStateGround;
                } else if((d >= 0x30 || d <= 0x39) ||
                          d == 0x3b) {
                    // action param TODO
                    state = kStateCSIParam;
                } else if(d >= 0x3c || d <= 0x3f) {
                    // action collect TODO
                    state = kStateCSIParam;
                } else if(d >= 0x20 || d <= 0x2f) {
                    // action collect TODO
                    state = kStateCSIIntermediate;
                } else if(d >= 0x3a) {
                    state = kStateCSIIgnore;
                } // ignore 0x7f
                break;
            case kStateCSIParam:
                if(isControlChar(d) == YES) {
                    [_displayDelegate characterNonDisplay:d];
                } else if(d >= 0x40 || d <= 0x7e) {
                    // action csi_dispatch TODO
                    state = kStateGround;
                } else if((d >= 0x3c && d <= 0x3f) ||
                          d == 0x3a) {
                    state = kStateCSIIgnore;
                }
                break;
            case kStateCSIIntermediate:
                if(isControlChar(d) == YES) {
                    [_displayDelegate characterNonDisplay:d];
                } else if(d >= 0x20 && d <= 0x2f) {
                    // action collect TODO
                } else if(d >= 0x30 && d <= 0x3f) {
                    state = kStateCSIIgnore;
                } else if(d >= 0x40 && d <= 0x7e) {
                    // action csi_dispatch TODO
                    state = kStateGround;
                } // ignore 0x7f
                break;
            case kStateCSIIgnore:
                if(isControlChar(d) == YES) {
                    [_displayDelegate characterNonDisplay:d];
                } else if(d >= 0x40 && d <= 0x7e) {
                    state = kStateGround;
                } // ignore 0x20-0x3f and 0x7f
                break;
            case kStateDCSEntry:
                // ignore control chars here
                if(d >= 0x20 && d <= 0x2f) {
                    // action collect TODO
                    state = kStateDCSIntermediate;
                } else if(d == 0x3a) {
                    state = kStateDCSIgnore;
                } else if((d >= 0x30 && d <= 0x39) ||
                          d == 0x3b) {
                    // action param TODO
                    state = kStateDCSParam;
                } else if(d >= 0x3c && d <= 0x3f) {
                    // action collect TODO
                    state = kStateDCSParam;
                } else if(d >= 0x40 && d <= 0x7e) {
                    // action hook TODO
                    state = kStateDCSPassthrough;
                } // ignore 0x7f
                break;
            case kStateDCSParam:
                // ignore control chars here
                if((d >= 0x30 && d < 0x39) || d == 0x3b) {
                    // action param TODO
                } else if((d >= 0x3c && d < 0x3f) || d == 0x3a) {
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
        
    if(len > 0) {
        dataForDisplay = [NSMutableData dataWithBytes:c length:len];
        // more data to display, allow run loop to continue and return here
        [self performSelector:@selector(processDataChunk) withObject:nil afterDelay:0.0f];
    } else {
        dataForDisplay = nil;
    }
}

#pragma mark -
#pragma mark TerminalIdentityDelegate

// display each of the bytes in the view advancing cursor position
- (void)displayData:(NSData *)data {
    
    if(dataForDisplay == nil)
        dataForDisplay = [data mutableCopy];
    else
        [dataForDisplay appendData:data];
    
    // processDataChunk is a method that can proceed with display until it should break,
    // e.g. to facilitate terminal animation or other ancient tricks.
    [self processDataChunk];
}

@end
