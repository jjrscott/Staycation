//
//  main.m
//  sty
//
//  Created by John Scott on 17/04/2014.
//  Copyright (c) 2014 John Scott. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "NSMutableArray+STYAdditions.h"

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        
        NSString *directory = [[paths firstObject] stringByAppendingPathComponent:@"com.jjrscott.staycation"];
        
        NSFileManager *defaultManager = [NSFileManager defaultManager];
        
        if (![defaultManager fileExistsAtPath:directory])
            [defaultManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
        
        NSString* termSessionId = [NSProcessInfo.processInfo.environment objectForKey:@"TERM_SESSION_ID"];
        
        NSString *path = [[directory stringByAppendingPathComponent:termSessionId] stringByAppendingPathExtension:@"staycation"];
        
        [defaultManager createFileAtPath:path contents:nil attributes:nil];
        
        NSFileHandle *cacheFileHandle = [NSFileHandle fileHandleForWritingAtPath:path];

        NSMutableArray *arguments = [NSMutableArray arrayWithArray:NSProcessInfo.processInfo.arguments];
        [arguments STYAdditions_popFirstObject];
        NSString *argument = nil;
        BOOL hasAddedHeader = NO;
        while ((argument = [arguments STYAdditions_popFirstObject]) != nil)
        {
            if ([argument isEqual:@"--header"] || [argument isEqual:@"-H"])
            {
                NSString *value = [arguments STYAdditions_popFirstObject];
                [cacheFileHandle writeData:[value dataUsingEncoding:NSUTF8StringEncoding]];
                [cacheFileHandle writeData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                hasAddedHeader = YES;
            }
            else
            {
                NSLog(@"Unknown argument: %@", argument);
                exit(1);
            }
        }
        
        if (!hasAddedHeader)
        {
            [cacheFileHandle writeData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        }
        [cacheFileHandle writeData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];

        NSUInteger dataLength = 1;
        while (dataLength > 0)
        {
            NSData *data = [[NSFileHandle fileHandleWithStandardInput] availableData];
            [cacheFileHandle writeData:data];
            dataLength = [data length];
        }
        
        [cacheFileHandle closeFile];
        
        NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:@[@"-b", @"com.jjrscott.staycation", path]];
        [task waitUntilExit];
    }
    return 0;
}

