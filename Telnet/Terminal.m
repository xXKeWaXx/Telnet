//
//  Terminal.m
//  xterminal
//
//  Created by Adam Eberbach on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Terminal.h"

@implementation Terminal

#define kTerminalRows (24)
#define kTerminalColumns (80)

@synthesize displayDelegate;

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

// interpret the 
- (void)processCommand:(NSData *)command {
    [self logCommand:command];
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

@end
