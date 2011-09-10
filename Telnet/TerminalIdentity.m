
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
            commandValue = 1;
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
            
            if([numericValues count] == 0) {
                row = 1;
                col = 1;
            } else {
                row = [[numericValues objectAtIndex:0] intValue];
                col = [[numericValues objectAtIndex:1] intValue];
            }
            [_displayDelegate cursorSetRow:row column:col];
            [numericValues removeAllObjects];
            handled = YES;
        } else if([commandIdentifier isEqualToString:@"J"]) {
            switch(commandValue) {
                case 0:
                    [_displayDelegate clearCursorAbove];
                    break;
                case 1:
                    [_displayDelegate clearCursorBelow];
                    break;
                default:
                    [_displayDelegate clearAll];
                    break;
            }
            if([numericValues count] > 0)
                [numericValues removeObjectAtIndex:0];
            handled = YES;
        } else if([commandIdentifier isEqualToString:@"K"]) {
            switch(commandValue) {
                case 0:
                    [_displayDelegate clearCursorRight];
                    break;
                case 1:
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

- (void)processANSICommandSequence:(unsigned char *)sequence withLength:(int)len {
    
    NSString *commandIdentifier = [NSString string];
    NSMutableArray *numericValues = [NSMutableArray array];
    CommandState state = kCommandStart;
    int numeric;
    
    while(len--) {
        
        unsigned char d = *sequence++;
        switch(state) {
            case kCommandStart:
                if(d >= 060 && d <= 071) {
                    // starting a numeric sequence
                    state = kCommandNumeric;
                    numeric = d - 060;
                } else {
                    // process command 
                    commandIdentifier = [commandIdentifier stringByAppendingFormat:@"%c", d];
                }
                break;
            case kCommandNumeric:
                if(d >= 060 && d <= 071) {
                    // continuing a numeric sequence
                    numeric *= 10;
                    numeric += d - 060;
                } else if (d == ';') {
                    // a compound argument command. Add the numeric received so far to an array of
                    // values and clear the value for a possible next value
                    [numericValues addObject:[NSNumber numberWithInt:numeric]];
                    numeric = 0;
                    
                } else {
                    if(numeric > 0) {
                        [numericValues addObject:[NSNumber numberWithInt:numeric]];
                    }
                    commandIdentifier = [commandIdentifier stringByAppendingFormat:@"%c", d];
                    state = kCommandStart;
                }
                break;
        }
    }
    
    
    if([self recognisedCommand:commandIdentifier withNumerics:numericValues] == NO) {
        NSLog(@"Unhandled ANSICommand: %@", commandIdentifier);
        if([numericValues count] > 0)
            NSLog(@"%@", numericValues);
    }
}

- (void)processDECCommandSequence:(unsigned char *)sequence withLength:(int)len {
    NSString *commandDebugString = [NSString string];
    
    while(len--) {
        commandDebugString = [commandDebugString stringByAppendingFormat:@"%c", *sequence++];
    }
    NSLog(@"DECCommand: %@", commandDebugString);
}


- (void)processCommandSequence:(NSData *)command {
    
    unsigned char * c = (unsigned char *)[command bytes];
    int len = [command length];
    
    if(*c++ != 033) {
        NSLog(@"command must start with ESC");
        return;
    }
    len--;
    
    if(*c == '[') {
        // eat the '['
        [self processANSICommandSequence:++c withLength:--len];
    } else {
        [self processDECCommandSequence:c withLength:len];
    }
}

- (void)processDataChunk {
    
    unsigned char *c = (unsigned char *)[dataForDisplay bytes];
    int len = [dataForDisplay length];
    TelnetDataState dataState = kTelnetDataStateRest;
    
    NSMutableData *command = [NSMutableData data];
    BOOL continuing = YES;
    
    while(len-- && continuing) {
        
        unsigned char d = *c++;
        
        switch(dataState) {
                
            case kTelnetDataStateRest: {
                
                // simplest case - not part of a command sequence, output a glyph
                if([self isTelnetPrintable:d]) {
                    
                    [_displayDelegate characterDisplay:d];
                    break;
                    
                    // individual special characters
                } else if ([self isTelnetControl:d]) {
                    
                    [_displayDelegate characterNonDisplay:d];
                    break;
                    
                } else if (d == 016) { // SQ invoke G1 character set
                } else if (d == 017) { // SI invoke G0 character set
                } else if (d == 021) { // XON resume transmission
                } else if (d == 023) { // XOFF pause transmission                    
                } else if (d == 033) { // ESC initiate control sequence
                    [command appendBytes:&d length:1];
                    dataState = kTelnetDataStateESC;
                } else if (d == 0177) { // ignored
                }
            }
                break;
                
            case kTelnetDataStateESC: {
                
                if (d == 0133) { // [ - enter CSI state
                    [command appendBytes:&d length:1];
                    dataState = kTelnetDataStateCSI;
                } else if (d == 033) { // ESC - discard all preceding control sequence construction, begin again
                    command = [NSMutableData dataWithBytes:&d length:1];
                } else if (d == 0104 || d == 0105 || d == 0115) { // D index, E newline, M reverse index
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0101 || d == 0102 || d == 060 || d == 061 || d == 062) { // A UK, B USASCII, 0 Special graphics, 1 alt ROM, 2 alt ROM special graphics
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                    
                } else if (d == 067 || d == 070) { // 7 save cursor, 8 restore cursor
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 030 || d == 032) { // CAN, SUB cancel current control sequence
                    command = nil;
                    continuing = NO;
                } else if (d == 050 || d == 051) { // ( G0 designator, ) G1 designator
                    [command appendBytes:&d length:1];
                } else {
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                }
            }
                break;
                
            case kTelnetDataStateCSI: {
                
                if(d == 033) { // ESC - discard all preceding control sequence construction, begin again
                    command = [NSMutableData dataWithBytes:&d length:1];
                } else if ((d >= 060 && d <= 071) || (d == 073)) { // Numeric or the ';' char
                    [command appendBytes:&d length:1];
                } else {
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                }
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
