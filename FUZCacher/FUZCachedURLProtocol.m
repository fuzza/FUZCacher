//
//  FUZCachedURLProtocol.m
//  FUZCacher
//
//  Created by fuzza on 7/16/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import "FUZCachedURLProtocol.h"

@interface FUZCachedURLProtocol () <NSURLConnectionDelegate>

@property (nonatomic, strong) NSURLConnection *connection;

@end

@implementation FUZCachedURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    
    if ([NSURLProtocol propertyForKey:NSStringFromClass([self class]) inRequest:request]) {
        return NO;
    }
    
    return ([request.URL.scheme isEqualToString:@"http"] &&
            ([request.URL.pathExtension isEqualToString:@"mp4"] || [request.URL.pathExtension isEqualToString:@"m3u8"]));
}

+ (BOOL)canInitWithTask:(NSURLSessionTask *)task {
    
    if ([NSURLProtocol propertyForKey:@"MyURLProtocolHandledKey" inRequest:task.originalRequest]) {
        return NO;
    }
    
    return ([task.originalRequest.URL.scheme isEqualToString:@"http"] &&
            ([ task.originalRequest.URL.pathExtension isEqualToString:@"mp4"] || [ task.originalRequest.URL.pathExtension isEqualToString:@"m3u8"]));
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading {
    
    NSMutableURLRequest *newRequest = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:NSStringFromClass([self class]) inRequest:newRequest];
    
    self.connection = [NSURLConnection connectionWithRequest:newRequest
                                                    delegate:self];
}

- (void)stopLoading {
   
    [self.connection cancel];
}

#pragma mark - NSURConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
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
