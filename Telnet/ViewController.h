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
@class TerminalIdentity;

@interface ViewController : UIViewController <UITextViewDelegate> {
    
    UITextView *inputTextView;
    TelnetConnection *connection;
    TerminalIdentity *identity;
}

@end
