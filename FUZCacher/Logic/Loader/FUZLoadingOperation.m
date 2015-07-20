//
//  FUZLoadingOperation.m
//  FUZCacher
//
//  Created by fuzza on 7/18/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import "FUZLoadingOperation.h"
#import "FUZPartialLoadingRequest.h"
#import "FUZCacheEntity.h"
#import "NSDictionary+FUZHTTPHeaders.h"

NSInteger const kHTTPPartialRequestSuccessCode = 206;
NSInteger const kHTTPNotModifiedSuccessCode = 304;

@interface FUZLoadingOperation () <NSURLConnectionDelegate>

@property (nonatomic, assign, getter=isFinished) BOOL finished;
@property (nonatomic, assign, getter=isExecuting) BOOL executing;

@property (nonatomic, strong) NSURLConnection *connection;

@property (nonatomic, assign, getter=isReadFromCache) BOOL readFromCache;
@property (nonatomic, assign, getter=isLoaded) BOOL loaded;

@end

@implementation FUZLoadingOperation

@synthesize finished = _finished;
@synthesize executing = _executing;

#pragma mark - NSOperation lifecycle

- (void)start
{
    self.executing = YES;
    self.readFromCache = [self.cache canReadFromCacheWithOffset:[self.loadingRequest requiredOffset]];
    if(self.isReadFromCache && ![self.loadingRequest isMetadataRequest])
    {
        [self receiveDataFromCache];
    }
    else
    {
        [self receiveDataFromNetwork];
    }
}

- (void)finishWithError:(NSError *)error
{
    if(self.connection)
    {
        [self.connection cancel];
        self.connection = nil;
    }
    self.loaded = YES;
    
    [self.loadingRequest finishWithError:nil];

    self.executing = NO;
    self.finished = YES;
}

#pragma mark - Methods

- (void)receiveDataFromCache
{
    if(self.loadingRequest.isMetadataRequest)
    {
        NSDictionary *cachedHeaders = [self.cache copyResponseFromCache].allHeaderFields;
        [self.loadingRequest fillWithResponseHeaders:cachedHeaders];
    }
    
    @weakify(self);
    [self.cache readFromCacheFromOffset:[self.loadingRequest requiredOffset] withLength:[self.loadingRequest requiredLength] cacheBlock:^(NSData *cacheBlock, BOOL *stop)
     {
         @strongify(self);
         if(self.isCancelled)
         {
             *stop = YES;
             return;
         }
        [self.loadingRequest fillWithData:cacheBlock];
     }];
    
    [self finishWithError:nil];
}

- (void)receiveDataFromNetwork
{
    NSMutableURLRequest *request = [self.loadingRequest httpRequest];

    if(self.isReadFromCache)
    {
        NSString *modifiedSince = [[self.cache copyResponseFromCache].allHeaderFields fuz_responseLastModifiedValue];
        [request setValue:modifiedSince forHTTPHeaderField:kIfModifiedSinceHeaderKey];
    }
    
    NSLog(@"%@", request.allHTTPHeaderFields);
    
    NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [self.connection scheduleInRunLoop:currentRunLoop forMode:NSRunLoopCommonModes];
    [self.connection start];
    while (!self.isLoaded && [currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]])
    {
        /**Empty loop**/
    }
}

#pragma mark - Mutators / Accessors

- (BOOL)isAsynchronous
{
    return YES;
}

- (void)setIsExecuting:(BOOL)executing
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
    _executing = executing;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
}

- (void)setIsFinished:(BOOL)finished
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
    _finished = finished;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    NSLog(@"%@", response);
    if(self.loadingRequest.isMetadataRequest && response.statusCode == kHTTPPartialRequestSuccessCode)
    {
        [self.cache writeResponseToCache:response];
        [self.loadingRequest fillWithResponseHeaders:response.allHeaderFields];
        if(self.isReadFromCache)
        {
            [self.cache invalidate];
        }
    }
    if(response.statusCode == kHTTPNotModifiedSuccessCode)
    {
        [self receiveDataFromCache];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if(self.isCancelled)
    {
        [self finishWithError:nil];
        return;
    }
    
    if(!self.loadingRequest.isMetadataRequest)
    {
        //Cache to filesystem only data request
        [self.cache writeDataToCache:data withOffset:[self.loadingRequest currentLocation]];
    }
    [self.loadingRequest fillWithData:data];
    
    if(self.isCancelled)
    {
        [self finishWithError:nil];
        return;
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self finishWithError:nil];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self finishWithError:error];
}

@end
