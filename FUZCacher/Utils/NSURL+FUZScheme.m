//
//  NSURL+FUZScheme.m
//  FUZCacher
//
//  Created by fuzza on 7/18/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import "NSURL+FUZScheme.h"

@implementation NSURL (FUZScheme)

- (NSURL *)fuz_urlWithScheme:(NSString *)scheme
{
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:self resolvingAgainstBaseURL:NO];
    components.scheme = scheme;
    return [components URL];
}

@end
