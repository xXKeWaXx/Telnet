//
//  ViewController.m
//  Telnet
//
//  Created by Adam Eberbach on 20/08/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "Display.h"
#import "Parser.h"
#import "Terminal.h"
#import "TelnetConnection.h"

//#import "TerminalView.h"
//#import "TerminalIdentity.h"

@interface ViewController (private)
- (void)calculateAvailableDisplayDimensions;
@end

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
          
- (void)setDisplayRows:(int)rows andColumns:(int)columns {

    CGSize displaySize = [Display sizeForRows:rows andColumns:columns];
    // centre terminal within the screen on a pixel boundary
    CGFloat displayOrigin = floorf((availableWidth - displaySize.width) / 2);

    // switch terminal to handle new row & column count
    [terminal setRows:rows andColumns:columns];
    
    // size display for rows and columns
    display.frame = CGRectMake(displayOrigin, 0.f, displaySize.width, displaySize.height);
    
    // input text view needs to be somewhere hidden. This should probably move to behind the telnet window
    inputTextView = [[UITextView alloc] initWithFrame:CGRectZero];
}

- (void)sizeDisplayToFit {
    
    // use as many rows and columns of the current glyph size as fit in the current orientation
    [self calculateAvailableDisplayDimensions];
    
    // read row & column from user prefs initially
    CGFloat glyphHeight = [display glyphHeight];
    CGFloat glyphWidth = [display glyphWidth];
    int rows = floorf(availableHeight / glyphHeight) - 1;
    int columns = availableWidth / glyphWidth;
    
    [self setDisplayRows:rows andColumns:columns];

}
#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.view setBackgroundColor:[UIColor blackColor]];
    display = [[Display alloc] initWithFrame:CGRectZero]; 
    [self.view addSubview:display];

    connection = [[TelnetConnection alloc] init];
    [connection setOptions:nil];
    terminal = [[Terminal alloc] init];
    parser = [[Parser alloc] init];
    
    parser.terminalDelegate = terminal;
    connection.parserDelegate = parser;
    terminal.displayDelegate = display;
    terminal.connectionDelegate = connection;

    [self sizeDisplayToFit];
    
    inputTextView.text = @"X";
    inputTextView.delegate = self;
    [self.view addSubview:inputTextView];
    [inputTextView becomeFirstResponder];

    [self.view bringSubviewToFront:display];
    
        // enable telnet
        // sudo sh-3.2# launchctl
        // launchd% load -F /System/Library/LaunchDaemons/telnet.plist

    [connection open:@"127.0.0.1" port:23];

    //[connection open:@"nethack.kraln.com" port:23];
//    [connection open:@"mud.genesismud.org" port:3011];
//    [connection open:@"nethack.alt.org" port:23];
//    [connection open:@"sporkhack.com" port:23];
//    [connection open:@"nethack.eu" port:23];

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

// Screen rotation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

- (void)calculateAvailableDisplayDimensions {
    
    switch(self.interfaceOrientation) {
            
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            keyboardHeight = 264.f;
            availableWidth = 768.f;
            availableHeight = 1024.f - keyboardHeight - keyboardAdditionHeight;
            break;
        default:
            keyboardHeight = 352.f;
            availableWidth = 1024.f;
            availableHeight = 768.f - keyboardHeight - keyboardAdditionHeight;
            break;
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

    
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {

    [self sizeDisplayToFit];
}

@end
