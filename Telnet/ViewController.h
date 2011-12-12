//
//  ViewController.h
//  Telnet
//
//  Created by Adam Eberbach on 20/08/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "TerminalIdentity.h"

@class Display;
@class TelnetConnection;
@class Terminal;
@class Parser;

@interface ViewController : UIViewController <UITextViewDelegate> {
    
    UITextView *inputTextView;
    
    Display *display;
    TelnetConnection *connection;
    Terminal *terminal;
    Parser *parser;
    
    CGFloat availableWidth;
    CGFloat availableHeight;
    CGFloat keyboardHeight;
    CGFloat keyboardAdditionHeight;

}

@end
