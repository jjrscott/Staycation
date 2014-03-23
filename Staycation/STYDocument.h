//
//  STYDocument.h
//  Staycation
//
//  Created by John Scott on 22/03/2014.
//  Copyright (c) 2014 John Scott. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface STYDocument : NSDocument

@property (nonatomic, strong) IBOutlet WebView *webView;
@property (nonatomic, strong) NSURL *absoluteURL;

-(IBAction)reloadPage:(id)sender;

@end
