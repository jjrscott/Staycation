//
//  NSThread+STYAdditions.m
//  Staycation
//
//  Created by John Scott on 23/03/2014.
//  Copyright (c) 2014 John Scott. All rights reserved.
//

#import "NSThread+STYAdditions.h"

@implementation NSThread (STYAdditions)

- (void)STYAdditions_performBlockInBackground:(void (^)())block
{
    if ([[NSThread currentThread] isEqual:self])
    {
        block();
    }
    else
    {
        [self performSelector:_cmd onThread:self withObject:block waitUntilDone:NO];
    }
}

@end
