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

- (IBAction)installComandLineTools:(id)sender
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"sty" ofType:nil];
    
//    [[NSTask launchedTaskWithLaunchPath:@"/usr/bin/sudo" arguments:@[@"-A", @"cp", @"-pr", path, @"/usr/local/bin/sty"]] waitUntilExit];
    
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSError *error = nil;
//    [fileManager copyItemAtPath:path toPath:@"/usr/local/bin/sty" error:&error];
    
    NSString *output = nil;
    NSString *errorDescription = nil;
    
    [self runProcessAsAdministrator:@"/bin/cp"
                      withArguments:@[@"-pr", path, @"/usr/local/bin/sty"]
                             output:&output
                   errorDescription:&errorDescription];
}

/*
 http://stackoverflow.com/a/15248621
 */

- (BOOL) runProcessAsAdministrator:(NSString*)scriptPath
                     withArguments:(NSArray *)arguments
                            output:(NSString **)output
                  errorDescription:(NSString **)errorDescription {
    
    NSString * allArgs = [arguments componentsJoinedByString:@" "];
    NSString * fullScript = [NSString stringWithFormat:@"'%@' %@", scriptPath, allArgs];
    
    NSDictionary *errorInfo = [NSDictionary new];
    NSString *script =  [NSString stringWithFormat:@"do shell script \"%@\" with administrator privileges", fullScript];
    
    NSAppleScript *appleScript = [[NSAppleScript new] initWithSource:script];
    NSAppleEventDescriptor * eventResult = [appleScript executeAndReturnError:&errorInfo];
    
    // Check errorInfo
    if (! eventResult)
    {
        // Describe common errors
        *errorDescription = nil;
        if ([errorInfo valueForKey:NSAppleScriptErrorNumber])
        {
            NSNumber * errorNumber = (NSNumber *)[errorInfo valueForKey:NSAppleScriptErrorNumber];
            if ([errorNumber intValue] == -128)
                *errorDescription = @"The administrator password is required to do this.";
        }
        
        // Set error message from provided message
        if (*errorDescription == nil)
        {
            if ([errorInfo valueForKey:NSAppleScriptErrorMessage])
                *errorDescription =  (NSString *)[errorInfo valueForKey:NSAppleScriptErrorMessage];
        }
        
        return NO;
    }
    else
    {
        // Set output to the AppleScript's output
        *output = [eventResult stringValue];
        
        return YES;
    }
}

@end
