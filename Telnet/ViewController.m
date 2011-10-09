//
//  ViewController.m
//  Telnet
//
//  Created by Adam Eberbach on 20/08/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "TelnetConnection.h"
#import "TerminalView.h"
#import "TerminalIdentity.h"

@implementation ViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma - mark TerminalResponderDelegate

- (void)sendResponse:(TerminalResponseType)response {
    
    uint8_t esc = 0x1b;
    uint8_t csi = '[';
    uint8_t question = '?';
    uint8_t semi = ';';
    uint8_t numeric;
    
    NSMutableData *responseData = [NSMutableData data];
    [responseData appendBytes:&esc length:1];
    
    switch(response) {
        case kResponseTerminalIdentity:
            [responseData appendBytes:&csi length:1];
            [responseData appendBytes:&question length:1];
            numeric = '1';
            [responseData appendBytes:&numeric length:1];
            [responseData appendBytes:&semi length:1];
            numeric = '0';
            [responseData appendBytes:&numeric length:1];
            numeric = 'c';
            [responseData appendBytes:&numeric length:1];
            
            break;
        default:
            NSLog(@"TerminalIdentity requested strange response to host");
            break;
    }
    
    [connection sendData:responseData];
}


#pragma - mark UITextViewDelegate
- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    return NO;
}

- (void)textViewDidChange:(UITextView *)textView {

    // textView doesn't send any control chars such as ESC, CTRL-C - some manual handling required
 //   [identity displayData:[NSData dataWithBytes:[textView.text cStringUsingEncoding:NSASCIIStringEncoding] length:[textView.text length]]];
    
    [connection sendString:textView.text];
    textView.text = nil;
}
// UITextViewDelegate ends

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    
    // terminal view is the class that displays terminal interaction.
    // It implements TerminalDisplayDelegate
    TerminalView *terminalView = [[TerminalView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:terminalView];
    CGFloat termWidth = terminalView.frame.size.width;
    
    CGRect terminalRect = terminalView.frame;
    terminalRect.origin.x = (768 - termWidth) / 2;
    terminalRect.origin.y = terminalRect.origin.x;
    terminalView.frame = terminalRect;

    inputTextView = [[UITextView alloc] initWithFrame:CGRectMake(terminalRect.origin.x, terminalRect.origin.y + terminalRect.size.height + 10, terminalRect.size.width, 18.f)];
    inputTextView.delegate = self;
    [self.view addSubview:inputTextView];
    [inputTextView becomeFirstResponder];
    
    // terminal identity is the terminal's personality, defining it as VT220, xTerm etc.
    identity = [[TerminalIdentity alloc] init];
    identity.displayDelegate = terminalView;
    identity.responderDelegate = self;
    
    // connection object manages the actual connection through GCDAsyncSocket
    connection = [[TelnetConnection alloc] init];
    connection.identityDelegate = identity;
    [connection setOptions:nil];
    
        // enable telnet
        // sudo sh-3.2# launchctl
        // launchd% load -F /System/Library/LaunchDaemons/telnet.plist

//    [connection open:@"172.16.0.230" port:23];
    [connection open:@"127.0.0.1" port:23];

//    [connection open:@"nethack.kraln.com" port:23];
//    [connection open:@"mud.genesismud.org" port:3011];
//    [connection open:@"nethack.alt.org" port:23];
//    [connection open:@"sporkhack.com" port:23];
    [connection read];
//    [connection read];
//    [connection read];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

@end
