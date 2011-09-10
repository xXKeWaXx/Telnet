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

#pragma - mark UITextViewDelegate
- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    return NO;
}

- (void)textViewDidChange:(UITextView *)textView {
    
    [connection send:textView.text];
    textView.text = nil;
}
// UITextViewDelegate ends

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    
    // terminal view is the class that displays terminal interaction.
    // It implements TerminalDisplayDelegate
    TerminalView *terminalView = [[TerminalView alloc] initWithFrame:CGRectMake(0.f, 0.f, 0.f, 0.f)];
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
    
    // connection object manages the actual connection through GCDAsyncSocket
    connection = [[TelnetConnection alloc] init];
    connection.identityDelegate = identity;
    
    [connection setOptions:nil];

//[connection open:@"mud.genesismud.org" port:3011];
    [connection open:@"nethack.alt.org" port:23];
//    [connection open:@"batmud.bat.org" port:23];
    [connection read];
    [connection read];
    [connection read];
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
