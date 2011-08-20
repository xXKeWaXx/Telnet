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

@implementation ViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    TerminalView *terminalView = [[TerminalView alloc] initWithFrame:CGRectMake(0.f, 0.f, 0.f, 0.f)];
    [self.view addSubview:terminalView];
    CGFloat termWidth = terminalView.frame.size.width;
    
    CGRect terminalRect = terminalView.frame;
    terminalRect.origin.x = (768 - termWidth) / 2;
    terminalRect.origin.y = terminalRect.origin.x;
    terminalView.frame = terminalRect;

    connection = [[TelnetConnection alloc] init];
    connection.displayDelegate = terminalView;
    [connection open:@"mud.genesismud.org" port:3011];
//    [connection open:@"nethack.alt.org" port:23];

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
