//
//  STYAppDelegate.m
//  Staycation
//
//  Created by John Scott on 17/04/2014.
//  Copyright (c) 2014 John Scott. All rights reserved.
//

#import "STYAppDelegate.h"

#import "STYDocument.h"

@implementation STYAppDelegate

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
    NSURL *url = [[NSURL alloc] initFileURLWithPath:filename];
    
    for (STYDocument *document in [[NSDocumentController sharedDocumentController] documents])
    {
        if ([url isEqual:document.fileURL])
        {
            [document reloadPage:nil];
            break;
        }
    }
    
    return NO;
}

@end
