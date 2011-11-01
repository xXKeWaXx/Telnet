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
#define COMMAND_DEFAULT_VALUE (255)

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
    
    deferredAdvance = NO;

    if(modeDECOM == NO) {
        if(row > terminalRows)
            row = terminalRows;
        if(row < 1)
            row = 1;
    } else {
        if(row > bottomRow)
            row = bottomRow;
        if(row < topRow)
            row = topRow;
    }
    if(col > terminalColumns)
        col = terminalColumns;

    termRow = row;
    termCol = col;
}

- (void)decrementRow {

    if(termRow > 1) {
        [self setRow:termRow - 1 andColumn:termCol];
    } else {
        // reverse scroll (down)
        NSLog(@"Would scroll screen down but not implemented");
    }
}

// check for origin mode, handle scrolling, in simple cases just increment termRow
- (void)advanceRow {

    if((modeDECOM == YES) && (termRow == bottomRow)) {
        
        [displayDelegate scrollUpRegionTop:topRow regionSpan:bottomRow - (topRow - 1)];
        
    } else if(termRow == terminalRows) {
        
        [displayDelegate scrollUpRegionTop:1 regionSpan:terminalRows];
        
    } else {
        [self setRow:termRow + 1 andColumn:termCol];
    }
}

- (void)decrementColumn {
        
    if((termCol == 1) && (modeDECRAWM == YES)) {
        [self setRow:termRow andColumn:terminalColumns];
        [self decrementRow];
    } else {
        if(termCol > 1)
            [self setRow:termRow andColumn:termCol - 1];
    }
}

- (void)advanceColumn {
    
    if((modeDECAWM == YES) && (termCol == terminalColumns)) {
        [self advanceRow];
        [self setRow:termRow andColumn:1];
    } else {
        if(termCol < terminalColumns)
            [self setRow:termRow andColumn:termCol + 1];;
    }
}


// reset everything for a new connection
- (void)reset {
    
    [self setRow:1 andColumn:1];
    
    // tab stops are initially every 8 characters beginning in the first column
    int tabStop = 1;
    tabStops = [[NSMutableArray alloc] init];
    do {
        
        [tabStops addObject:[NSNumber numberWithInt:tabStop]];
        tabStop += 8;
        
    }while(tabStop < terminalColumns);
    
    modeDECOM = NO;
    modeDECAWM = NO;
    modeDECRAWM = NO;
    
    foregroundColor = kGlyphColorDefault;
    backgroundColor = kGlyphColorDefault;
    currentAttributes = 0;
    
    // cause glyphs to be created and laid out for the display
    [displayDelegate resetScreenWithRows:terminalRows andColumns:terminalColumns];
}

- (void)eraseRow:(int)row {
    for(int i = 1; i <= terminalColumns; i++) {
        [displayDelegate displayChar:0x20 atRow:row atColumn:i];
    }
}

- (void)clearCursorLeft {
    // clear from start of row to cursor inclusive
    for(int i = 1; i <= termCol; i++) {
        [displayDelegate displayChar:0x20 atRow:termRow atColumn:i];
    }
}

- (void)clearCursorRight {
    // clear from cursor to end of row inclusive
    for(int i = termCol; i <= terminalColumns; i++) {
        [displayDelegate displayChar:0x20 atRow:termRow atColumn:i];
    }
}

// ANSI command 'K'
- (void)commandEraseLine:(unsigned char)argument {
    switch(argument) {
        case '0': // clear from cursor through end of line
            [self clearCursorRight];
            break;
        case '1': // clear from beginning of line through cursor
            [self clearCursorLeft];
            break;
        default:
            [self eraseRow:termRow];
            break;
    }
}

- (void)commandEraseScreen:(unsigned char)argument {
    switch(argument) {
        case '0': 
            [self clearCursorRight];
            // clear rest of rows below cursor
            for(int i = termRow + 1; i <= terminalRows; i++) {
                [self eraseRow:i];
            }
            break;
        case '1':
            // clear rows above cursor row
            for(int i = 1; i < termRow; i++) {
                [self eraseRow:i];
            }
            [self clearCursorLeft];
            break;
        default: // clear all
            for(int i = 1; i < terminalRows; i++) {
                [self eraseRow:i];
            }
            break;
    }
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

- (int)findTabIndex:(int)col {
    
    int location = INT_MAX;
    int index = 0;
    
    for(NSNumber *tabStopNumber in tabStops) {
        if([tabStopNumber intValue] == termCol) {
            location = index;
            break;
        }
        index++;
    }
    return location;
}

- (void)clearTabs:(int)option {
    
    if(option == 3) {
        
        // clear all tabs
        [tabStops removeAllObjects];
        
    } else if((option == 0) || (option == COMMAND_DEFAULT_VALUE)) {
        
        // clear tab at current column
        int location = [self findTabIndex:termCol];
        
        if(location != INT_MAX)
            [tabStops removeObjectAtIndex:location];
    }
    
}

- (void)setTab:(int)col {
    
    // don't set a tab if already set
    if([self findTabIndex:termCol] == INT_MAX) {
        [tabStops addObject:[NSNumber numberWithInt:termCol]];
    }
}
#pragma mark -
#pragma mark Identify and act on command sequences


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
          
        case 'g': // clear tabs
            count = [self parseSimpleNumeric:sequence length:len];
            [self clearTabs:count];
            break;
        case 'h': // SET DEC private modes DECSET
        {
            arguments = [self parseNumerics:sequence length:len];
            unsigned char *bytes = [arguments mutableBytes];
            
            if(*bytes == '?') {
                switch(*(bytes + 1)) {
                        
                    case 3: 
                        // P s = 3 → 132 Column Mode (DECCOLM)
//                        [_displayDelegate setColumns:132];
                        break;
                    case 5:
                        // Send: <27> [ ? 5 h Reverse Video (DECSCNM).
                        currentAttributes |= kModeInverse;
                        [displayDelegate setAttributes:currentAttributes foreground:foregroundColor background:backgroundColor];
                        break;

                    case 6:
                        // P s = 6 → Origin Mode (DECOM)
                        modeDECOM = YES;
                        // cursor home
                        [self setRow:topRow andColumn:1];

                        break;
                    case 7:
                        // P s = 7 → Wraparound Mode (DECAWM) 
                        modeDECAWM = YES;
                        break;
                    case 40:
                        // P s = 4 0 → Allow 80 → 132 Mode
                        break;

                    case 45:
                        // Send: <27> [ ? 4 5 h Enable Reverse-wraparound Mode. 
                        modeDECRAWM == YES;
                        break;
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
                       
                    case 1:
                        // Send: <27> [ ? 1 1 → Normal Cursor Keys (DECCKM). 
                        NSLog(@"Normal Cursor Keys (DECCKM), should send ANSI sequences");
                        break;
                    case 3:
                        // Send: <27> [ ? 3 l 80 Column Mode (DECCOLM). 
                        [displayDelegate setColumns:80];
                        [self setRow:topRow andColumn:1];
                        break;
                    case 4:
                        // Send: <27> [ ? 4 l Jump (Fast) Scroll (DECSCLM).
                        NSLog(@"Jump (Fast) Scroll (DECSCLM) (smooth scroll not implemented yet)");
                        break;
                    case 5:
                        // Send: <27> [ ? 5 l Normal Video (DECSCNM).  
                        currentAttributes &= ~kModeInverse;
                        [displayDelegate setAttributes:currentAttributes foreground:foregroundColor background:backgroundColor];
                        break;
                    case 6:
                        // Send: <27> [ ? 6 l Normal Cursor Mode (DECOM). 
                        modeDECOM = NO;
                        break;
                    case 7:
                        // Send: <27> [ ? 7 h No Wraparound Mode (DECAWM). 
                        modeDECAWM = NO;
                        break;
                    case 8:
                        // Send: <27> [ ? 8 l No Auto-repeat Keys (DECARM). 
                        NSLog(@"No Auto-repeat Keys (DECARM) (not implemented yet)");
                        break;
                    case 40:
                        // Send: <27> [ ? 4 0 h Disallow 80 → 132 Mode. 
                        NSLog(@"Disallow 80 → 132 Mode (not implemented yet)");
                        break;
                    case 45:
                        // Send: <27> [ ? 4 5 l No Reverse-wraparound Mode. 
                        modeDECRAWM == NO;
                        break;

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
                
                currentAttributes = 0;
                foregroundColor = kGlyphColorDefault;
                backgroundColor = kGlyphColorDefault;
            } else {

                arguments = [self parseNumerics:sequence length:len];
                unsigned char *bytes = [arguments mutableBytes];
                
                for(int i = 0; i < len; i++) {
                    uint8_t c = *(bytes + i);
                    switch(c) {
                        case 0: // normal
                            currentAttributes = 0;
                            break;
                        case 1: // bold
                            currentAttributes |= kModeBold;
                            break;
                        case 4: // underscore
                            currentAttributes |= kModeUnderscore;
                            break;
                        case 5: // blink
                            currentAttributes |= kModeBlink;
                            break;
                        case 7: // inverse
                            currentAttributes |= kModeInverse;
                            break;
                        case 22: // normal (bold, faint off)
                            currentAttributes &= ~kModeBold;
                            currentAttributes &= ~kModeBlink;
                            break;
                        case 24: // underline off
                            currentAttributes &= ~kModeUnderscore;
                            break;
                        case 25: // blink off
                            currentAttributes &= kModeBold;
                            break;
                        case 27: // inverse off
                            currentAttributes &= kModeInverse;
                            break;
                        case 30: // fg black
                            foregroundColor = kGlyphColorBlack;
                            break;
                        case 31: // fg red
                            foregroundColor = kGlyphColorRed;
                            break;
                        case 32: // fg green
                            foregroundColor = kGlyphColorGreen;
                            break;
                        case 33: // fg yellow
                            foregroundColor = kGlyphColorYellow;
                            break;
                        case 34: // fg blue
                            foregroundColor = kGlyphColorBlue;
                            break;
                        case 35: // fg magenta
                            foregroundColor = kGlyphColorMagenta;
                            break;
                        case 36: // fg cyan
                            foregroundColor = kGlyphColorCyan;
                            break;
                        case 37: // fg white
                            foregroundColor = kGlyphColorGray;
                            break;
                        case 39: // fg default
                            foregroundColor = kGlyphColorDefault;
                            break;
                        case 40: // bg black
                            backgroundColor = kGlyphColorBlack;
                            break;
                        case 41: // bg red
                            backgroundColor = kGlyphColorRed;
                            break;
                        case 42: // bg green
                            backgroundColor = kGlyphColorGreen;
                            break;
                        case 43: // bg yellow
                            backgroundColor = kGlyphColorYellow;
                            break;
                        case 44: // bg blue
                            backgroundColor = kGlyphColorBlue;
                            break;
                        case 45: // bg magenta
                            backgroundColor = kGlyphColorMagenta;
                            break;
                        case 46: // bg cyan
                            backgroundColor = kGlyphColorCyan;
                            break;
                        case 47: // bg white
                            backgroundColor = kGlyphColorGray;
                            break;
                        case 49: // bg default
                            backgroundColor = kGlyphColorDefault;
                            break;
                        default:
                            NSLog(@"Unknown parameter for CSI m: %d", c);
                            break;
                    }
                }
            }
            [displayDelegate setAttributes:currentAttributes foreground:foregroundColor background:backgroundColor];
        }
            break;
        case 'r': // set top and bottom margins DECSTBM
        {
            if(len == 0) {
                
                topRow = 1;
                bottomRow = terminalRows;
                [self setRow:topRow andColumn:1]; // always move to position 1,1

            } else {
                
                // setting top and bottom margin
                arguments = [self parseNumerics:sequence length:len];
                unsigned char *bytes = [arguments mutableBytes];
                uint8_t topValue = *bytes;
                uint8_t bottomValue = *(bytes + 1);
                
                if(topValue <= bottomValue) {
                
                    if((topValue != COMMAND_DEFAULT_VALUE) && (topValue != 0)) {
                        // if the value is zero or omitted, the margin is unchanged
                        topRow = topValue;
                    }
                    if(topRow < 1)
                        topRow = 1;
                    
                    if((bottomValue != COMMAND_DEFAULT_VALUE) && (bottomValue != 0)) {
                        // if the value is zero or omitted, the margin is unchanged
                        bottomRow = bottomValue;
                    }
                    if(bottomRow > terminalRows)
                        bottomRow = terminalRows;
                }
                [self setRow:topRow andColumn:1]; // always move to position 1,1
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
            
            while((count--) && ((modeDECOM) ? (termRow > topRow) : (termRow > 1)))
                [self setRow:termRow - 1 andColumn:termCol];
        }
            break;
        case 'B': // CUD cursor down
        {
            count = [self parseSimpleNumeric:sequence length:len];
            if(count == COMMAND_DEFAULT_VALUE)
                count = 1;
            
            if(count == 0)
                count = 1;
            
            while((count--) && ((modeDECOM) ? (termRow < bottomRow) : (termRow < terminalRows)))
                [self setRow:termRow + 1 andColumn:termCol];
        }
            break;
        case 'C': // CUF cursor forward
        {
            count = [self parseSimpleNumeric:sequence length:len];
            if(count == COMMAND_DEFAULT_VALUE)
                count = 1;
            
            if(count == 0)
                count = 1;
            
            while((count--) && (termCol < terminalColumns))
                [self setRow:termRow andColumn:termCol + 1];
        }
            break;
        case 'D': // CUB cursor backward
        {
            count = [self parseSimpleNumeric:sequence length:len];
            if(count == COMMAND_DEFAULT_VALUE)
                count = 1;
            
            if(count == 0)
                count = 1;
            
            while((count--) && (termCol > 1))
                [self setRow:termRow andColumn:termCol - 1];
        }
            break;
        case 'I': // tab something
        {
            NSLog(@"What should CSI 'I' do?");
        }
            break;
            
        case 'J': // ED erase in dsplay
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
        case 'K': // EL Erase in line
        {            
            switch(len) {
                case 0: // default erase to end of screen
                    [self commandEraseLine:'0'];
                    break;
                case 1: 
                    [self commandEraseLine:*sequence];
                    break;
            }
        }
            break;
        case 'H':
        case 'f': // HVP horizontal and vertical position
        {
            // default (if len is zero)
            int newRow = 1;
            int newCol = 1;

            if(len != 0) {
                arguments = [self parseNumerics:sequence length:len];
                unsigned char *bytes = [arguments mutableBytes];
                newRow = *bytes;
                newCol = *(bytes + 1);

                if(modeDECOM == YES) {
                    newRow += (topRow - 1);
                    if(newRow > bottomRow)
                        newRow = bottomRow;
                }

                if(newRow == COMMAND_DEFAULT_VALUE)
                    newRow = 1;
                if(newCol == COMMAND_DEFAULT_VALUE)
                    newCol = 1;
            }
            [self setRow:newRow andColumn:newCol];
        }
            break;
        case 'Z': // tab something
        {
            NSLog(@"What should CSI 'Z' do?");
        }
            break;

        default:
            NSLog(@"Unhandled ANSI command sequence finalChar %c", finalChar);
            break;
    }
    
}

- (void)processDECCommandSequence:(unsigned char *)sequence withLength:(int)len {
    
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
    
    switch(finalChar) {
        case '8': {
            if(len == 0) {
                // restore cursor previously saved attributes
                NSLog(@"unhandled DEC command sequence ending in 8");
            } else if ((len == 1) && (*sequence == '#')) {
                // test mode; fill screen with 'E' chars (DECALN)
                for(int i = (modeDECOM ? 1 : topRow); i <= (modeDECOM ? bottomRow : terminalRows); i++) {
                    for(int j = 1; j < terminalColumns; j++) {
                        [displayDelegate displayChar:'E' atRow:i atColumn:j];
                    }
                }
            }
        }
            break;
            
        case 'B':
            NSLog(@"What is B supposed to do?");
            break;
        case 'D': { // IND cursor index
            [self advanceRow];
            
        }
            break;
        case 'E': { // NEL first position on next line
            [self advanceRow];
            [self setRow:termRow andColumn:1];
        }
            break;
        case 'H': { // HTS set tab at this position
            [self setTab:termCol];
        } 
            break;
        case 'M': { // RI
            [self decrementRow];
        }
            break;
        default:
            NSLog(@"Unhandled DEC command sequence %c", finalChar);
            break;
    }
}


#pragma mark -
#pragma mark TerminalDelegate

- (void)characterDisplay:(unsigned char)c {

    // if character would be displayed in final column
    if(termCol == terminalColumns) {
        // if advance was deferred
        if(deferredAdvance == YES)
            // advance column before character display
            [self advanceColumn];
    }
    
    // always clear deferred state
    deferredAdvance = NO;

    // display the character
    [displayDelegate displayChar:c atRow:termRow atColumn:termCol];
    
    // if not in final column, advance. Else record that an advance was deferred
    if(termCol < terminalColumns) {
        [self advanceColumn];
    } else {
        deferredAdvance = YES;
    }
}

- (void)characterNonDisplay:(unsigned char)c {
    
    if(deferredAdvance == YES) {
        // advance column before character display
        //[self advanceColumn];
        deferredAdvance = NO;
    }
    

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
            [self setRow:termRow andColumn:1];
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
                tab = terminalColumns;
            NSLog(@"tabbed to col %d", tab);
            [self setRow:termRow andColumn:tab];
        }
            break;
        case kTelnetCharBS:            
            // move the cursor back
            [self decrementColumn];
            break;
        case kTelnetCharBEL:
            NSLog(@"ding!");
            break;
        case kTelnetCharNUL:
        default:
            break;
    }
}

// interpret the 
- (void)processCommand:(NSData *)command {
    
//    [self logCommand:command];

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
        [self processDECCommandSequence:[reversedCommand mutableBytes] withLength:[reversedCommand length]];
    }
}

@end
