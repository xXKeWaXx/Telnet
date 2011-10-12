//
//  ConnectionDelegate.h
//  xterminal
//
//  Created by Adam Eberbach on 13/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ConnectionDelegate <NSObject>
- (void)sendData:(NSData *)sendData;
@end