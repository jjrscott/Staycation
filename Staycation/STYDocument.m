//
//  STYDocument.m
//  Staycation
//
//  Created by John Scott on 22/03/2014.
//  Copyright (c) 2014 John Scott. All rights reserved.
//

#import "STYDocument.h"
#import "SpecialProtocol.h"
#import "NSData+STYAdditions.h"

@implementation STYDocument
{
    NSString *_title;
    BOOL _keepTitle;
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
    _keepTitle = NO;
	[[self.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:self.absoluteURL]];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    return nil;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    NSString *file = [absoluteURL path];
    
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:file error:NULL];
    
    NSString *baseString = nil;
    NSString *pathString = nil;

    if ([fileAttributes[NSFileType] isEqual:NSFileTypeDirectory])
    {
        baseString = file;
        pathString = @"";
    }
    else
    {
        baseString = [file stringByDeletingLastPathComponent];
        pathString = [file lastPathComponent];
    }
    
    baseString = [[baseString dataUsingEncoding:NSUTF8StringEncoding] STYAdditions_hexEncodedString];
    
    NSString *urlString = [NSString stringWithFormat:@"http://%@/%@", baseString, pathString];
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
    if (title != nil && !_keepTitle)
    {
        _title = title;
        [self.windowForSheet setTitle:[self displayName]];
    }
}

-(IBAction)reloadPage:(id)sender
{
    _keepTitle = NO;
    [_webView reloadFromOrigin:sender];
}

-(NSString*)displayName
{
    return _title ?: [super displayName];
}

- (void)webView:(WebView *)sender resource:(id)identifier didReceiveResponse:(NSHTTPURLResponse *)response fromDataSource:(WebDataSource *)dataSource
{
    NSString *title = response.allHeaderFields[@"X-STY-Title"];
    if (title != nil)
    {
        _title = title;
        _keepTitle = YES;
        [self.windowForSheet setTitle:[self displayName]];
    }
}

@end
