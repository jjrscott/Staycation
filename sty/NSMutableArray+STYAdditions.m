//
//  NSMutableArray+STYAdditions.m
//  Staycation
//
//  Created by John Scott on 17/04/2014.
//  Copyright (c) 2014 John Scott. All rights reserved.
//

#import "NSMutableArray+STYAdditions.h"

@implementation NSMutableArray (STYAdditions)

- (id)STYAdditions_popFirstObject
{
    id object = nil;
    if ([self count] > 0)
    {
        object = [self objectAtIndex:0];
        [self removeObjectAtIndex:0];
        return object;
    }
    return object;
}

@end
