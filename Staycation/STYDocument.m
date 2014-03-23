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
    _webView.resourceLoadDelegate = nil;
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

- (void)webView:(WebView *)sender resource:(id)identifier didFinishLoadingFromDataSource:(WebDataSource *)dataSource;
{
    NSString *displayName = [_webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if ([displayName length] == 0)
    {
        displayName = nil;
    }
    [self.windowForSheet setTitle:displayName];
}

-(IBAction)reloadPage:(id)sender
{
    [_webView reloadFromOrigin:sender];
}

@end
