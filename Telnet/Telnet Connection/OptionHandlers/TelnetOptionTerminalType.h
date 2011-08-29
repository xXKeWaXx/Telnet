//
//  TelnetOptionTerminalType.h
//  Telnet
//
//  Created by Adam Eberbach on 29/08/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TelnetOptionHandler.h"

@interface TelnetOptionTerminalType : TelnetOptionHandler

- (NSData *)processSB:(NSData *)dataForSubnegotiation;

@end
