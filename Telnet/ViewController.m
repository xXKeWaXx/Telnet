//
//  ViewController.m
//  Telnet
//
//  Created by Adam Eberbach on 20/08/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "TelnetConnection.h"
#import "Display.h"
#import "Parser.h"
#import "Terminal.h"

//#import "TerminalView.h"
//#import "TerminalIdentity.h"

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

    // determine whether the key was a backspace
    if([textView.text isEqualToString:@""]) {
        uint8_t bsValue = kTelnetCharBS;
        [connection sendData:[NSData dataWithBytes:&bsValue length:1]];
    } else {
        // Not a backspace, send all but the 'X'
        NSRange allButX = NSMakeRange(1, 1);
        [connection sendString:[textView.text substringWithRange:allButX]];
    }
    textView.text = @"X";
}
// UITextViewDelegate ends

- (void)keyPressed:(NSNotification*)notification {
 
}
          
#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(keyPressed:) name:UITextInputCurrentInputModeDidChangeNotification object: nil];
    

//    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(keyPressed:) name: UITextFieldTextDidChangeNotification object: nil];
//    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(keyPressed:) name: UITextViewTextDidChangeNotification object: nil];
    
    CGSize displaySize = [Display sizeForRows:24 andColumns:80];
    CGFloat displayOrigin = (768 - displaySize.width) / 2;
    Display *display = [[Display alloc] initWithFrame:CGRectMake(displayOrigin,
                                                                 displayOrigin,
                                                                 displaySize.width,
                                                                 displaySize.height)];
    [self.view addSubview:display];


    connection = [[TelnetConnection alloc] init];
    [connection setOptions:nil];
    terminal = [[Terminal alloc] init];
    parser = [[Parser alloc] init];
    
    parser.terminalDelegate = terminal;
    connection.parserDelegate = parser;
    terminal.displayDelegate = display;
    terminal.connectionDelegate = connection;

    
    inputTextView = [[UITextView alloc] initWithFrame:CGRectMake(displayOrigin, 
                                                                 displayOrigin + displaySize.height + 10, 
                                                                 displaySize.width, 
                                                                 18.f)];
    inputTextView.text = @"X";
    inputTextView.delegate = self;
    [self.view addSubview:inputTextView];
    [inputTextView becomeFirstResponder];

        // enable telnet
        // sudo sh-3.2# launchctl
        // launchd% load -F /System/Library/LaunchDaemons/telnet.plist

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
