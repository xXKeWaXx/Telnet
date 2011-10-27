//
//  DisplayDelegate.h
//  xterminal
//
//  Created by Adam Eberbach on 13/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef uint16_t glyphAttributes;

#define kModeIntensity  (0x0001)
#define kModeDECSCNM    (0x0002)
#if 0
#define kModeUnused     (0x0004)
#define kModeUnused     (0x0008)
#define kModeUnused     (0x0010)
#define kModeUnused     (0x0020)
#define kModeUnused     (0x0040)
#define kModeUnused     (0x0080)
#define kModeUnused     (0x0100)
#define kModeUnused     (0x0200)
#define kModeUnused     (0x0400)
#define kModeUnused     (0x0800)
#define kModeUnused     (0x1000)
#define kModeUnused     (0x2000)
#define kModeUnused     (0x4000)
#define kModeUnused     (0x8000)
#endif
@protocol DisplayDelegate <NSObject>
- (void)resetScreenWithRows:(int)rows andColumns:(int)cols;
- (void)displayChar:(uint8_t)c 
              atRow:(int)row 
           atColumn:(int)col 
     withAttributes:(glyphAttributes)attributes;
- (void)scrollUpRegionTop:(int)top regionSpan:(int)rows;
- (void)setColumns:(int)cols;

@end
