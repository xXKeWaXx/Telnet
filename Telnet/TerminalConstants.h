//
//  TerminalConstants.h
//  xterminal
//
//  Created by Adam Eberbach on 10/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#ifndef xterminal_TerminalConstants_h
#define xterminal_TerminalConstants_h

typedef enum _TextAttributes {
    
    kTextAtributeClear = 0,
    kTextAttributeBright = 1,
    kTextAttributeDim = 2,
    kTextAttributeUnderscore = 4,
    kTextAttributeBlink = 5,
    kTextAttributeReverse = 7,
    kTextAttributeHidden = 8    
    
} TextAttributes;

typedef enum _TerminalDisplayColor {
    
    kTermColorBlack,
    kTermColorRed,
    kTermColorGreen,
    kTermColorYellow,
    kTermColorBlue,
    kTermColorMagenta,
    kTermColorCyan,
    kTermColorWhite
    
} TerminalDisplayColor;



#endif
