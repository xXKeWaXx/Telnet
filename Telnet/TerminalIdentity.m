
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
@synthesize responderDelegate = _responderDelegate;

// ANSI command 'J'
- (void)commandEraseScreen:(unsigned char)argument {
    switch(argument) {
        case '0': // clear from cursor to end of screen
            [_displayDelegate clearCursorBelow];
            break;
        case '1': // clear from beginning of screen to cursor
            [_displayDelegate clearCursorAbove];
            break;
        default: // clear all
            [_displayDelegate clearAll];
    }
}

// ANSI command 'K'
- (void)commandEraseLine:(unsigned char)argument {
    switch(argument) {
        case '0': // clear from cursor to end of line
            [_displayDelegate clearCursorRight];
            break;
        case '1': // clear from beginning of line to cursor
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
//    if(numeric == 0)
//        numeric = COMMAND_DEFAULT_VALUE;
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
        
    if(len) {
        while(len--) {
            thisChar = *(sequence + len);
            
            if(isFirstChar == YES) {
                if(thisChar == '?') {
                    // a ? indicates a report
                    [numericSequence appendBytes:&thisChar length:1];
                } else if(thisChar == ';') {
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
    }    
    return numericSequence;
}

// command sequence comes in reverse to make processing easier
- (void)processANSICommandSequence:(unsigned char *)sequence withLength:(int)len {
    
    NSMutableString *commandString = [NSMutableString string];
    
    for(int i = 1; i < len + 1; i++) {
        [commandString appendFormat:@"%c", *(sequence + (len - i))];
    }

    NSLog(@"Sequence: %@", commandString);
    
    unsigned char finalChar = *sequence;
    // finalChar is the first char, advance unless it is also last
    if(len > 0) {
        len--; 
        sequence++;
    }
    int count;
    NSMutableData *arguments;
    
    switch(finalChar) {
        case 'c': // interrogation VT220 p.46
        {
            count = [self parseSimpleNumeric:sequence length:len];
            if(count == 0) {
                // identified request to identify terminal type
                [_responderDelegate sendResponse:kResponseTerminalIdentity];
                
            }
        }
            break;
            
        case 'h':
        {
            arguments = [self parseNumerics:sequence length:len];
            unsigned char *bytes = [arguments mutableBytes];
            
            if(*bytes == '?') {
                switch(*(bytes + 1)) {
                        
                    case 3: 
                        // P s = 3 → 132 Column Mode (DECCOLM)
                        break;
                    case 6:
                        // P s = 6 → Origin Mode (DECOM)
                        break;
                    case 7:
                        // P s = 7 → Wraparound Mode (DECAWM) 
                        break;
                    case 40:
                        // P s = 4 0 → Allow 80 → 132 Mode
                        break;
                    default:
                        NSLog(@"%@", [NSString stringWithFormat:@"Got a ESC [ ? %d h not handled.", *(bytes + 1)]);
                        break;
                        
                }
            }
        }
            break;

        case 'l':
        {
            arguments = [self parseNumerics:sequence length:len];
            unsigned char *bytes = [arguments mutableBytes];
            
            if(*bytes == '?') {
                switch(*(bytes + 1)) {
                        
                    case 1:
                        // Send: <27> [ ? 1 1 → Normal Cursor Keys (DECCKM). 
                        break;
                    case 3:
                        // Send: <27> [ ? 3 l 80 Column Mode (DECCOLM). 
                        break;
                    case 4:
                        // Send: <27> [ ? 4 l Jump (Fast) Scroll (DECSCLM).
                        break;
                    case 5:
                        // Send: <27> [ ? 5 l Normal Video (DECSCNM).  
                        break;
                    case 6:
                        // Send: <27> [ ? 6 l Normal Cursor Mode (DECOM). 
                        break;
                    case 7:
                        // Send: <27> [ ? 7 h No Wraparound Mode (DECAWM). 
                        break;
                    case 8:
                        // Send: <27> [ ? 8 l No Auto-repeat Keys (DECARM). 
                        break;
                    case 40:
                        // Send: <27> [ ? 4 0 h Disallow 80 → 132 Mode. 
                        break;
                    case 45:
                        // Send: <27> [ ? 4 5 l No Reverse-wraparound Mode. 
                        break;
                    default:
                        NSLog(@"%@", [NSString stringWithFormat:@"Got a ESC [ ? %d l not handled.", *(bytes + 1)]);
                        break;
                        
                }
            }
        }
            break;
            
        case 'm': // set display attributes
        {
            if(len == 0) {
                // reset to default (plain) text
            } else {
                arguments = [self parseNumerics:sequence length:len];
                unsigned char *bytes = [arguments mutableBytes];
                if(*bytes == 0) {
                    // reset to default (plain) text
                } else {
                    // set text attribute according to value
                }
            }
        }
            break;
        case 'r': // set top and bottom margins
        {
            if(len == 0) {
                // Default margins (entire screen) set
            } else {
                
                // setting top and bottom margin
                arguments = [self parseNumerics:sequence length:len];
                unsigned char *bytes = [arguments mutableBytes];

                int topRow, bottomRow;
                
                if(*bytes == COMMAND_DEFAULT_VALUE)
                    topRow = 1;
                else 
                    topRow = *bytes;
                
                if(*(bytes + 1) == COMMAND_DEFAULT_VALUE)
                    bottomRow = 1;
                else 
                    bottomRow = *(bytes + 1);

            }
        }
            break;
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
            int rowPosition = 1;
            int columnPosition = 1;
            
            if(len == 0) {
                // home command
                rowPosition = 1;
                columnPosition = 1;
            } else {
                arguments = [self parseNumerics:sequence length:len];
                unsigned char *bytes = [arguments mutableBytes];
                rowPosition = *bytes;
                columnPosition = *(bytes + 1);
                
                
                if(rowPosition == COMMAND_DEFAULT_VALUE)
                    rowPosition = 1;
                if(columnPosition == COMMAND_DEFAULT_VALUE)
                    columnPosition = 1;
            }
            [_displayDelegate cursorSetRow:rowPosition column:columnPosition];
            
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
BOOL isPrintableChar(uint8_t character);

TerminalDataState transitionFromAnywhere(uint8_t character, int stateNow);

BOOL isControlChar(uint8_t character) {
    if ((character >= 0x00 && character <= 0x17) ||
        (character == 0x19) ||
        (character >= 0x1c && character <= 0x1f))
        return YES;
    return NO;
}

BOOL isPrintableChar(uint8_t character) {
    if(character >= 0x20 && character <= 0x7f)
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

void logCommand(NSMutableData *data);

void logCommand(NSMutableData *data) {
    
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
}

- (void)processDataChunk {
    
    unsigned char *c = (unsigned char *)[dataForDisplay bytes];
    int len = [dataForDisplay length];
    
    TerminalDataState state = kStateGround;
    TerminalDataState transitionState;
    NSMutableData *param = [NSMutableData data];
//    privateFlag;
//    intermediateCharacters;
//    finalCharacter;
//    parameters;
    
    while(len--) {
        uint8_t d = *c++;
        // some transitions can happen from "anywhere"
        if((transitionState = transitionFromAnywhere(d, state)) != state) {
            if(transitionState == kStateEsc) {
                
            }
            if(transitionState == kStateEsc ||
               transitionState == kStateDCSEntry ||
               transitionState == kStateCSIEntry) {
                // on entry, clear 
                //    privateFlag;
                //    intermediateCharacters;
                //    finalCharacter;
                param = [NSMutableData data];
                [param appendBytes:&d length:1];
            }
            state = transitionState;
            continue;
        }
        
        switch(state) {
            case kStateGround:
                if(isPrintableChar(d)) { 
                    // display printable chars
                    NSLog(@"Printable: %c", d);
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
                    param = [NSMutableData data];
                    state = kStateDCSEntry;
                } else if(d == 0x58 ||
                          d == 0x5e ||
                          d == 0x5f) {
                    state = kStateSOSPMAPCString;
                } else if(d == '[') {
                    // on entry, clear 
                    //    privateFlag;
                    //    intermediateCharacters;
                    //    finalCharacter;
                    [param appendBytes:&d length:1];
                    state = kStateCSIEntry;
                } else if(d == 0x5d) {
                    // sction osc_start TODO
                    state = kStateOSCString;
                } else if((d >= 0x30 && d <= 0x4f) ||
                          (d >= 0x51 && d <= 0x57) ||
                          d == 0x59 ||
                          d == 0x5a ||
                          d == 0x5c ||
                          (d >= 0x60 && d <= 0x7e)) {
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
                } else if(d >= 0x40 && d <= 0x7e) {
                    
                    [param appendBytes:&d length:1];
                    logCommand(param);
                    [self processCommandSequence:param];
                    state = kStateGround;
                } else if((d >= 0x30 && d <= 0x39) ||
                          d == 0x3b) {
                    [param appendBytes:&d length:1];
                    state = kStateCSIParam;
                } else if(d >= 0x3c && d <= 0x3f) {
                    [param appendBytes:&d length:1];
                    state = kStateCSIParam;
                } else if(d >= 0x20 && d <= 0x2f) {
                    // action collect TODO
                    state = kStateCSIIntermediate;
                } else if(d >= 0x3a) {
                    state = kStateCSIIgnore;
                } // ignore 0x7f
                break;
            case kStateCSIParam:
                if(isControlChar(d) == YES) {
                    [_displayDelegate characterNonDisplay:d];
                } else if((d >= 0x30 && d <= 0x39) ||
                          d == 0x3b) {
                    [param appendBytes:&d length:1];
                } else if(d >= 0x40 && d <= 0x7e) {
                    [param appendBytes:&d length:1];
                    logCommand(param);
                    [self processCommandSequence:param];
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
                    [param appendBytes:&d length:1];
                    logCommand(param);
                    [self processCommandSequence:param];
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
