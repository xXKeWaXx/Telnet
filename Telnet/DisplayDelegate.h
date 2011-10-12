//
//  DisplayDelegate.h
//  xterminal
//
//  Created by Adam Eberbach on 13/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef uint16_t glyphAttributes;

@protocol DisplayDelegate <NSObject>
- (void)resetScreenWithRows:(int)rows andColumns:(int)cols;
- (void)displayChar:(uint8_t)c 
              atRow:(int)row 
           atColumn:(int)col 
     withAttributes:(glyphAttributes)attributes;
@end
