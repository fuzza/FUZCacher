//
//  NSDictionary+FUZHTTPHeaders.m
//  FUZCacher
//
//  Created by fuzza on 7/18/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import "NSDictionary+FUZHTTPHeaders.h"

NSString * const kRequestHeaderRangeKey = @"Range";
NSString * const kRequestHeaderRangeHeaderSeparator = @"=";
NSString * const kRequestHeaderRangeValuesSeparator = @"-";

@implementation NSDictionary (FUZHTTPHeaders)

- (NSRange)fuz_requestBytesRangeValue
{
    NSString *rangeHeaderString = [self objectForKey:kRequestHeaderRangeKey];
    if(rangeHeaderString)
    {
        NSArray *rangeComponents = [rangeHeaderString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"=-"]];
        
        if(rangeComponents.count == 3)
        {
            return NSMakeRange(((NSString *)rangeComponents[1]).integerValue, ((NSString *)rangeComponents[2]).integerValue+1);
        }
    }
    
    return NSMakeRange(0, 0);
}

@end
