//
//  NSDictionary+FUZHTTPHeaders.m
//  FUZCacher
//
//  Created by fuzza on 7/18/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import "NSDictionary+FUZHTTPHeaders.h"

NSString * const kRequestHeaderRangeKey = @"Range";
NSString * const kIfModifiedSinceHeaderKey = @"If-Modified-Since";
NSString * const kContentRangeHeaderKey = @"Content-Range";
NSString * const kContentTypeHeaderKey = @"Content-Type";
NSString * const kLastModifiedHeaderKey = @"Last-Modified";

NSString * const kRequestHeaderRangeHeaderSeparators = @"=-";
NSString * const kRequestHeaderContentLengthSeparator = @"/";

@implementation NSDictionary (FUZHTTPHeaders)

#pragma mark - Request headers

- (NSRange)fuz_requestBytesRangeValue
{
    NSString *rangeHeaderString = [self objectForKey:kRequestHeaderRangeKey];
    if(rangeHeaderString)
    {
        NSArray *rangeComponents = [rangeHeaderString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:kRequestHeaderRangeHeaderSeparators]];
        
        if(rangeComponents.count == 3)
        {
            return NSMakeRange(((NSString *)rangeComponents[1]).integerValue, ((NSString *)rangeComponents[2]).integerValue+1);
        }
    }
    return NSMakeRange(0, 0);
}

#pragma mark - Response headers

- (NSInteger)fuz_responseContentRangeTotalLength
{
    NSString *contentRangeString = [self valueForKey:kContentRangeHeaderKey];
    if(contentRangeString)
    {
        NSArray *rangeComponents = [contentRangeString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:kRequestHeaderContentLengthSeparator]];
        return ((NSString *)[rangeComponents lastObject]).integerValue;
    }
    return 0;
}

- (NSString *)fuz_responseUTIFromContentTypeValue
{
    NSString *httpContentType = [self valueForKey:kContentTypeHeaderKey];
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
    return [self valueForKey:kLastModifiedHeaderKey];
}

@end
