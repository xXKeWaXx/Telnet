//
//  Terminal.m
//  xterminal
//
//  Created by Adam Eberbach on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Terminal.h"
#import "TelnetConstants.h"

@implementation Terminal

#define kTerminalRows (24)
#define kTerminalColumns (80)

@synthesize displayDelegate;
@synthesize connectionDelegate;

- (id)init {

    self = [super init];
    if(self != nil) {
        terminalRows = kTerminalRows;
        terminalColumns = kTerminalColumns;
    }
    return self;
}

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
#pragma mark Management of cursor

- (void)setRow:(int)row andColumn:(int)col {
    termRow = row;
    termCol = col;
}

- (void)advanceColumn {

    if(0) {
        // wrap enabled
    } else {
        if(termCol < kTerminalColumns)
            [self setRow:termRow andColumn:termCol + 1];
    }
}

// check for origin mode, handle scrolling, in simple cases just increment termRow
- (void)advanceRow {

    if(termRow < kTerminalRows)
        [self setRow:termRow + 1 andColumn:termCol];
}

// reset everything for a new connection
- (void)reset {
    
    termRow = termCol = 1;
    
    // tab stops are initially every 8 characters beginning in the first column
    int tabStop = 1;
    tabStops = [[NSMutableArray alloc] init];
    do {
        
        [tabStops addObject:[NSNumber numberWithInt:tabStop]];
        tabStop += 8;
        
    }while(tabStop < kTerminalColumns);
    
    // cause glyphs to be created and laid out for the display
    [displayDelegate resetScreenWithRows:terminalRows andColumns:terminalColumns];
}

// ESC [ ? 1 ; 2 c VT100

- (void)sendTerminalIdentity {
    
    uint8_t esc = 0x1b;
    uint8_t csi = '[';
    uint8_t question = '?';
    uint8_t semi = ';';
    uint8_t numeric;
    
    NSMutableData *responseData = [NSMutableData data];
    [responseData appendBytes:&esc length:1];    
    [responseData appendBytes:&csi length:1];
    [responseData appendBytes:&question length:1];
    numeric = '1';
    [responseData appendBytes:&numeric length:1];
    [responseData appendBytes:&semi length:1];
    numeric = '0';
    [responseData appendBytes:&numeric length:1];
    numeric = 'c';
    [responseData appendBytes:&numeric length:1];
            
    [connectionDelegate sendData:responseData];
}

#pragma mark -
#pragma mark Identify and act on command sequences

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
    if(numeric == 0)
        numeric = COMMAND_DEFAULT_VALUE;
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
            
            if(count == COMMAND_DEFAULT_VALUE) { // a '0' in other words
                // identified request to identify terminal type
                [self sendTerminalIdentity];
                
            }
        }
            break;
            
        case 'h': // SET DEC private modes DECSET
        {
            arguments = [self parseNumerics:sequence length:len];
            unsigned char *bytes = [arguments mutableBytes];
            
            if(*bytes == '?') {
                switch(*(bytes + 1)) {
/*                        
                    case 3: 
                        // P s = 3 → 132 Column Mode (DECCOLM)
                        [_displayDelegate setColumns:132];
                        break;
                    case 6:
                        // P s = 6 → Origin Mode (DECOM)
                        [_displayDelegate setOriginMode:YES];
                        break;
                    case 7:
                        // P s = 7 → Wraparound Mode (DECAWM) 
                        [_displayDelegate setAutoWrapMode:YES];
                        break;
                    case 40:
                        // P s = 4 0 → Allow 80 → 132 Mode
                        NSLog(@"unhandled");
                        break;
 */
                    default:
                        break;
                        
                }
            }
        }
            break;
            
        case 'l':  // RESET DEC private modes DECRST
        {
            arguments = [self parseNumerics:sequence length:len];
            unsigned char *bytes = [arguments mutableBytes];
            
            if(*bytes == '?') {
                switch(*(bytes + 1)) {
/*                        
                    case 1:
                        // Send: <27> [ ? 1 1 → Normal Cursor Keys (DECCKM). 
                        NSLog(@"Normal Cursor Keys (DECCKM)");
                        break;
                    case 3:
                        // Send: <27> [ ? 3 l 80 Column Mode (DECCOLM). 
                        [_displayDelegate setColumns:80];
                        break;
                    case 4:
                        // Send: <27> [ ? 4 l Jump (Fast) Scroll (DECSCLM).
                        NSLog(@"Jump (Fast) Scroll (DECSCLM)");
                        break;
                    case 5:
                        // Send: <27> [ ? 5 l Normal Video (DECSCNM).  
                        NSLog(@"Normal Video (DECSCNM)");
                        break;
                    case 6:
                        // Send: <27> [ ? 6 l Normal Cursor Mode (DECOM). 
                        [_displayDelegate setOriginMode:NO];
                        break;
                    case 7:
                        // Send: <27> [ ? 7 h No Wraparound Mode (DECAWM). 
                        [_displayDelegate setAutoWrapMode:NO];
                        break;
                    case 8:
                        // Send: <27> [ ? 8 l No Auto-repeat Keys (DECARM). 
                        NSLog(@"No Auto-repeat Keys (DECARM)");
                        break;
                    case 40:
                        // Send: <27> [ ? 4 0 h Disallow 80 → 132 Mode. 
                        NSLog(@"Disallow 80 → 132 Mode");
                        break;
                    case 45:
                        // Send: <27> [ ? 4 5 l No Reverse-wraparound Mode. 
                        NSLog(@"No Reverse-wraparound Mode");
                        break;
*/ 
                    default:
                        NSLog(@"?l unhandled");
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
//                [_displayDelegate setMarginsTop:0 bottom:0];
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
                
//                [_displayDelegate setMarginsTop:topRow bottom:bottomRow];
            }
        }
            break;
        case 'A': // CUU cursor up
        {
            count = [self parseSimpleNumeric:sequence length:len];
            if(count == COMMAND_DEFAULT_VALUE) 
                count = 1;
            
            if(count == 0)
                count = 1;
            
            while(count--)
                ;
//                [_displayDelegate cursorUp];
        }
            break;
        case 'B': // CUD cursor down
        {
            count = [self parseSimpleNumeric:sequence length:len];
            if(count == COMMAND_DEFAULT_VALUE)
                count = 1;
            
            if(count == 0)
                count = 1;
            
            while(count--)
                ;
//                [_displayDelegate cursorDown];
        }
            break;
        case 'C': // CUF cursor forward
        {
            count = [self parseSimpleNumeric:sequence length:len];
            if(count == COMMAND_DEFAULT_VALUE)
                count = 1;
            
            if(count == 0)
                count = 1;
            
            while(count--)
                ;
//                [_displayDelegate cursorRight];
        }
            break;
        case 'D': // CUB cursor backward
        {
            count = [self parseSimpleNumeric:sequence length:len];
            if(count == COMMAND_DEFAULT_VALUE)
                count = 1;
            
            if(count == 0)
                count = 1;
            
            while(count--)
                ;
//                [_displayDelegate cursorLeft];
        }
            break;
        case 'J': // ED erase in dsplay
        {
            switch(len) {
                case 0: // default erase to end of screen
//                    [self commandEraseScreen:'0'];
                    break;
                case 1: 
//                    [self commandEraseScreen:*sequence];
                    break;
            }
        }
            break;
        case 'K': // EL Erase in line
            switch(len) {
                case 0: // default erase to end of screen
//                    [self commandEraseLine:'0'];
                    break;
                case 1: 
//                    [self commandEraseLine:*sequence];
                    break;
            }
            break;
        case 'H':
        case 'f': // HVP horizontal and vertical position
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
//            [_displayDelegate cursorSetRow:rowPosition column:columnPosition];
            
        }
            break;
        default:
            NSLog(@"Unhandled ANSI command sequence finalChar %c", finalChar);
    }
    
}


#pragma mark -
#pragma mark TerminalDelegate

- (void)characterDisplay:(unsigned char)c {

    [displayDelegate displayChar:c atRow:termRow atColumn:termCol withAttributes:0];
    [self advanceColumn];
}

- (void)characterNonDisplay:(unsigned char)c {
    switch(c) {
        case kTelnetCharCR:
            [self setRow:termRow andColumn:1];
            break;
        case kTelnetCharFF:
        case kTelnetCharVT:
            [self advanceRow];
            break;
        case kTelnetCharLF:
            [self advanceRow];
            break;
        case kTelnetCharHT:            
            // advance to next horizontal tab position or right margin if there are no more
        {
            // look for next tabstop after current column position
            int tab = 0;
            for(NSNumber *tabStopNumber in tabStops) {
                if([tabStopNumber intValue] > termCol) {
                    tab = [tabStopNumber intValue];
                    break;
                }
            }
            if(tab == 0)
                tab = kTerminalColumns;
            [self setRow:termRow andColumn:tab];
        }
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

// interpret the 
- (void)processCommand:(NSData *)command {
    
    //[self logCommand:command];

    unsigned char * c = (unsigned char *)[command bytes];
    
    int len = [command length];
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
        ;
//        [self processDECCommandSequence:[reversedCommand mutableBytes] withLength:[reversedCommand length]];
    }
}

@end
