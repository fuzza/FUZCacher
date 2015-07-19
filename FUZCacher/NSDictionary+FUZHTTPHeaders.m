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

- (NSInteger)fuz_responseContentRangeTotalLength
{
    NSString *contentRangeString = [self valueForKey:@"Content-Range"];
    if(contentRangeString)
    {
        NSArray *rangeComponents = [contentRangeString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
        return ((NSString *)[rangeComponents lastObject]).integerValue;
    }
    return 0;
}

- (NSString *)fuz_responseUTIFromContentTypeValue
{
    NSString *httpContentType = [self valueForKey:@"Content-Type"];
    if(httpContentType)
    {
        CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType,(__bridge CFStringRef)(httpContentType),NULL);
        NSString *UTIString = (__bridge NSString *)(contentType);
        CFRelease(contentType);
        
        return UTIString;
    }
    return nil;
}

- (NSString *)fuz_responseLastModifiedValue
{
    return [self valueForKey:@"Last-Modified"];
}

@end
