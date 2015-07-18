//
//  FUZCachedChunk.m
//  FUZCacher
//
//  Created by fuzza on 7/18/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import "FUZCachedChunk.h"

@implementation FUZCachedChunk

- (NSMutableData *)data
{
    if(!_data)
    {
        _data = [NSMutableData new];
    }
    return _data;
}

- (BOOL)containsLocation:(NSInteger)location
{
    NSRange range = NSMakeRange(self.startOffset, self.length);
    return NSLocationInRange(location, range);
}

@end
