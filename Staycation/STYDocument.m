//
//  STYDocument.m
//  Staycation
//
//  Created by John Scott on 22/03/2014.
//  Copyright (c) 2014 John Scott. All rights reserved.
//

#import "STYDocument.h"
#import "SpecialProtocol.h"

@implementation STYDocument
{
    NSString *_title;
}

+(void)load
{
    [NSURLProtocol registerClass:[SpecialProtocol class]];
    [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"WebKitDeveloperExtras"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

-(void)dealloc
{
    _webView.frameLoadDelegate = nil;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"STYDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
	[[self.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:self.absoluteURL]];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    return nil;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    NSString *urlString = [NSString stringWithFormat:@"http://_%@",[[absoluteURL path] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    self.absoluteURL = [NSURL URLWithString:urlString];
    *outError = nil;
    return YES;
}

-(BOOL)isDocumentEdited
{
    return NO;
}

- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame
{
    _title = title;
    if ([_title length] == 0)
    {
        _title = nil;
    }
    [self.windowForSheet setTitle:_title];
}

-(IBAction)reloadPage:(id)sender
{
    [_webView reloadFromOrigin:sender];
}

-(NSString*)displayName
{
    return _title;
}

@end
