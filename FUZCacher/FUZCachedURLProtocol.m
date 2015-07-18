//
//  FUZCachedURLProtocol.m
//  FUZCacher
//
//  Created by fuzza on 7/16/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import "FUZCachedURLProtocol.h"
#import "FUZHTTPResponseCache.h"

NSString *const kFUZMP4RequestHeaderRangeKey = @"Range";

@interface FUZCachedURLProtocol () <NSURLConnectionDelegate>

@property (nonatomic, strong) NSURLConnection *connection;

@end

@implementation FUZCachedURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([NSURLProtocol propertyForKey:NSStringFromClass([self class]) inRequest:request])
    {
        return NO;
    }
    return ([request.URL.scheme isEqualToString:@"http"] && [request.URL.pathExtension isEqualToString:@"mp4"]);
}

+ (BOOL)canInitWithTask:(NSURLSessionTask *)task
{
    return [self canInitWithRequest:task.originalRequest];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
    NSMutableURLRequest *newRequest = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:NSStringFromClass([self class]) inRequest:newRequest];
    NSLog(@"request %@, headers %@", newRequest, [newRequest allHTTPHeaderFields]);
    
    
        self.connection = [NSURLConnection connectionWithRequest:newRequest
                                                        delegate:self];
}

- (void)stopLoading {
    [self.connection cancel];
    if(!self.connection)
    {
        [self.client URLProtocolDidFinishLoading:self];
    }
}

#pragma mark - Request handlers

- (BOOL)isFirstBytesRequest:(NSURLRequest *)request {
    NSString *rangeString = [request.allHTTPHeaderFields objectForKey:kFUZMP4RequestHeaderRangeKey];
    if([rangeString isEqualToString:@"bytes=0-1"]) {
        return YES;
    }
    return NO;
}

#pragma mark - NSURConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    NSLog(@"%@", response);
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}


@end
