//
//  ParserDelegate.h
//  xterminal
//
//  Created by Adam Eberbach on 13/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ParserDelegate <NSObject>
- (void)parseData:(NSData *)data;
- (void)connectionMade;
@end
