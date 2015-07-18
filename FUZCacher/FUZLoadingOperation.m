//
//  FUZLoadingOperation.m
//  FUZCacher
//
//  Created by fuzza on 7/18/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import "FUZLoadingOperation.h"
#import "NSURL+FUZScheme.h"
#import "NSDictionary+FUZHTTPHeaders.h"
#import "FUZHTTPResponseCache.h"

@import MobileCoreServices;

NSString *const kFUZDefaultScheme = @"http";

@interface FUZLoadingOperation () <NSURLConnectionDelegate>

@property (nonatomic, assign, getter=isFinished) BOOL finished;
@property (nonatomic, assign, getter=isExecuting) BOOL executing;

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSHTTPURLResponse *response;

@property (nonatomic, assign) NSRange requiredRange;
@property (nonatomic, assign) NSInteger currentLocation;

@property (nonatomic, assign) BOOL disableCaching;

@end

@implementation FUZLoadingOperation

@synthesize finished = _finished;
@synthesize executing = _executing;

#pragma mark - NSOperation lifecycle

- (void)start
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(start)
                               withObject:nil waitUntilDone:NO];
        return;
    }
    
    [self startExecuting];
    
    NSLog(@"%@", self.resourceLoadingRequest);
    
    BOOL canReadFromCache = [[FUZHTTPResponseCache sharedCache] canReadFromCacheWithOffset:self.currentLocation];
    if(canReadFromCache)
    {
        self.resourceLoadingRequest.contentInformationRequest.contentType = (__bridge NSString *)(kUTTypeMPEG4);
        self.resourceLoadingRequest.contentInformationRequest.contentLength = 21042737;
        self.resourceLoadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
        
        [[FUZHTTPResponseCache sharedCache] readFromCacheFromOffset:self.requiredRange.location withLength:self.requiredRange.length cacheBlock:^(NSData *cacheBlock, BOOL isLastBlock, NSInteger totalCachedLength)
         {
             if(self.isCancelled)
             {
                 NSLog(@"%@ cancelled", self);
                 [self.connection cancel];
                 self.connection = nil;
                 [self stopExecuting];
                 return;
             }
             
             [self.resourceLoadingRequest.dataRequest respondWithData:cacheBlock];
             self.currentLocation += cacheBlock.length;
         }];
        
        if(self.isCancelled)
        {
            return;
        }
        
        [self.resourceLoadingRequest finishLoading];
        [self stopExecuting];
    }
    else
    {
        NSMutableURLRequest *request = [self.resourceLoadingRequest.request mutableCopy];
        NSLog(@"%@", request.allHTTPHeaderFields);
        
        request.URL = [request.URL fuz_urlWithScheme:kFUZDefaultScheme];
        request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        
        self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
        [self.connection start];
    }
}

#pragma mark - Mutators / Accessors

- (BOOL)isAsynchronous
{
    return YES;
}

- (void)setExecuting:(BOOL)executing
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
    _executing = executing;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
}

- (void)setFinished:(BOOL)finished
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
    _finished = finished;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
}

- (void)setResourceLoadingRequest:(AVAssetResourceLoadingRequest *)resourceLoadingRequest
{
    _resourceLoadingRequest = resourceLoadingRequest;
    
    self.requiredRange = NSMakeRange(self.resourceLoadingRequest.dataRequest.requestedOffset, self.resourceLoadingRequest.dataRequest.requestedLength);
    self.currentLocation = self.requiredRange.location;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    NSLog(@"%@", response);
    dispatch_async(dispatch_get_main_queue(), ^()
    {
        self.resourceLoadingRequest.contentInformationRequest.contentType = [response.allHeaderFields fuz_responseUTIFromContentTypeValue];
        self.resourceLoadingRequest.contentInformationRequest.contentLength = [response.allHeaderFields fuz_responseContentRangeTotalLength];
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
        [[FUZHTTPResponseCache sharedCache] writeDataToCache:data withOffset:self.currentLocation];
        self.currentLocation += data.length;
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
    self.finished = NO;
    self.executing = YES;
}

- (void)stopExecuting
{
    self.executing = NO;
    self.finished = YES;
}

@end
