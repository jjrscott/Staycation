//
//  NSThread+STYAdditions.h
//  Staycation
//
//  Created by John Scott on 23/03/2014.
//  Copyright (c) 2014 John Scott. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSThread (STYAdditions)

- (void)STYAdditions_performBlockInBackground:(void (^)())block;

@end
