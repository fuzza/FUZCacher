//
//  FUZLoadingOperation.m
//  FUZCacher
//
//  Created by fuzza on 7/18/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import "FUZLoadingOperation.h"
#import "NSURL+FUZScheme.h"
#import "FUZHTTPResponseCache.h"

@import MobileCoreServices;

 NSString *const kFUZDefaultScheme = @"http";

@interface FUZLoadingOperation () <NSURLConnectionDelegate>

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *receivedData;

@property (nonatomic, assign, getter=isFinished) BOOL finished;
@property (nonatomic, assign, getter=isExecuting) BOOL executing;

@property (nonatomic, assign) NSInteger dataOffset;

@property (nonatomic, assign) BOOL disableCaching;

@property (nonatomic, assign) NSRange requiredRange;

@end

@implementation FUZLoadingOperation

@synthesize finished = _finished;
@synthesize executing = _executing;

- (void)start
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(start)
                               withObject:nil waitUntilDone:NO];
        return;
    }
    
    [self startExecuting];
    
    self.requiredRange = NSMakeRange(self.resourceLoadingRequest.dataRequest.requestedOffset, self.resourceLoadingRequest.dataRequest.requestedLength);
    self.dataOffset = self.requiredRange.location;
    
    NSMutableURLRequest *request = [self.resourceLoadingRequest.request mutableCopy];
    request.URL = [request.URL fuz_urlWithScheme:kFUZDefaultScheme];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

    
    NSLog(@"%@", self.resourceLoadingRequest);
    NSLog(@"%@", request.allHTTPHeaderFields);
    
    BOOL canReadFromCache = [[FUZHTTPResponseCache sharedCache] canReadFromCacheWithOffset:self.dataOffset];
    if(canReadFromCache)
    {
        NSLog(@"can read from cache with offset %ld", (long)self.dataOffset);
        NSHTTPURLResponse *cachedResponse = [FUZHTTPResponseCache sharedCache].cachedResponse;
    
        self.resourceLoadingRequest.contentInformationRequest.contentType = (__bridge NSString *)(kUTTypeMPEG4);
        self.resourceLoadingRequest.contentInformationRequest.contentLength = 21042737;
        self.resourceLoadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
        
        [[FUZHTTPResponseCache sharedCache] readFromCacheFromOffset:self.requiredRange.location withLength:self.requiredRange.length cacheBlock:^(NSData *cacheBlock, BOOL isLastBlock, NSInteger totalCachedLength)
         {
             if(self.isCancelled)
             {
                 [self.connection cancel];
                 self.connection = nil;
                 [self stopExecuting];
                 return;
             }
             
             [self.resourceLoadingRequest.dataRequest respondWithData:cacheBlock];
             self.dataOffset += cacheBlock.length;
         }];
        
        if(self.isCancelled)
        {
            return;
        }
        
        [self.resourceLoadingRequest finishLoading];
        [self stopExecuting];
        return;
        NSInteger loadedLenght = self.dataOffset - self.requiredRange.location;
        if(loadedLenght < self.requiredRange.length)
        {
            NSMutableURLRequest *partialRequest = [self.resourceLoadingRequest.request mutableCopy];
            partialRequest.URL = [request.URL fuz_urlWithScheme:kFUZDefaultScheme];
            [partialRequest setValue:[NSString stringWithFormat:@"bytes=%ld-%ld", self.dataOffset, self.requiredRange.location+self.requiredRange.length-1] forHTTPHeaderField:@"Range"];
            partialRequest.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
            
            self.disableCaching = YES;

            self.connection = [NSURLConnection connectionWithRequest:partialRequest delegate:self];
            [self.connection start];
            NSLog(@"%@ started partial", self);
        }
        else
        {
            [self.resourceLoadingRequest finishLoading];
            [self stopExecuting];
        }
    }
    else
    {
        self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
        [self.connection start];
    }
}

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isAsynchronous
{
    return YES;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    NSLog(@"%@", response);
    if(self.disableCaching)
    {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^()
    {
        //            NSString *mimeType = item.path.mimeTypeForPathExtension;
        //            CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType,(__bridge CFStringRef)(mimeType),NULL);
        self.resourceLoadingRequest.contentInformationRequest.contentType = (__bridge NSString *)(kUTTypeMPEG4);
        self.resourceLoadingRequest.contentInformationRequest.contentLength = 21042737;
        self.resourceLoadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
    });
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if(self.isCancelled)
    {
        NSLog(@"%@ cancelled", self);
        [self.connection cancel];
        self.connection = nil;
        [self stopExecuting];
        return;
    }
    
    if(self.resourceLoadingRequest.contentInformationRequest == nil)
    {
        //Won't cache content information request
        [[FUZHTTPResponseCache sharedCache] writeDataToCache:data withOffset:self.dataOffset];
        self.dataOffset += data.length;
    }
    
    
    dispatch_async(dispatch_get_main_queue(), ^()
                   {
                       [self.resourceLoadingRequest.dataRequest respondWithData:data];
                   });
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    dispatch_async(dispatch_get_main_queue(), ^()
                   {
                       [self.resourceLoadingRequest finishLoading];
                   });
    
    [self stopExecuting];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^()
                   {
                       [self.resourceLoadingRequest finishLoadingWithError:error];
                   });
    
    [self stopExecuting];
}

- (void)startExecuting
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
    [self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
    _executing = YES;
    _finished = NO;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
    [self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
}

- (void)stopExecuting
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
    [self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
    _executing = NO;
    _finished = YES;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
    [self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
}
@end
