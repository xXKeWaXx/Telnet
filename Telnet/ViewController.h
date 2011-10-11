//
//  ViewController.h
//  Telnet
//
//  Created by Adam Eberbach on 20/08/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TerminalIdentity.h"

@class TelnetConnection;
@class Terminal;
@class Parser;

@interface ViewController : UIViewController <UITextViewDelegate, TerminalResponderDelegate> {
    
    UITextView *inputTextView;
    
    TelnetConnection *connection;
    Terminal *terminal;
    Parser *parser;
}

@end
