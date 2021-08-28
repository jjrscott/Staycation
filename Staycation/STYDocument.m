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

@interface STYDocument ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) BOOL keepTitle;

@end

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
    self.keepTitle = NO;
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
    if (title != nil && !self.keepTitle)
    {
        self.title = title;
        [self.windowForSheet setTitle:[self displayName]];
    }
}

-(IBAction)reloadPage:(id)sender
{
    self.keepTitle = NO;
    [_webView reloadFromOrigin:sender];
}

-(IBAction)toggleDarkMode:(id)sender {
    if (self.windowForSheet.appearance) {
        self.windowForSheet.appearance = nil;
    } else {
        self.windowForSheet.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    }
}

-(IBAction)darkMode:(id)sender {
    self.windowForSheet.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
}

-(IBAction)lightMode:(id)sender {
    self.windowForSheet.appearance = nil;
}

-(NSString*)displayName
{
    return self.title ?: [super displayName];
}

- (void)webView:(WebView *)sender resource:(id)identifier didReceiveResponse:(NSHTTPURLResponse *)response fromDataSource:(WebDataSource *)dataSource
{
    NSString *title = response.allHeaderFields[@"X-STY-Title"];
    if (title != nil)
    {
        self.title = title;
        self.keepTitle = YES;
        [self.windowForSheet setTitle:[self displayName]];
    }
}

- (void)webView:(WebView *)webView decidePolicyForNewWindowAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request
   newFrameName:(NSString *)frameName
decisionListener:(id<WebPolicyDecisionListener>)listener
{
    [NSWorkspace.sharedWorkspace openURL:request.URL];
    [listener ignore];
}

@end
