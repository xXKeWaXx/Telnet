//
//  TelnetOptionHandler.h
//  Telnet
//
//  Created by Adam Eberbach on 29/08/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TelnetConstants.h"

@interface TelnetOptionHandler : NSObject {
    
    BOOL _acceptsOption;
    BOOL _hostPerforms;
}

@property (nonatomic) BOOL acceptsOption;
@property (nonatomic) BOOL hostPerforms;

@end
