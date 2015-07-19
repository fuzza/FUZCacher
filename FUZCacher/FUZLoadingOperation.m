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
#import "FUZCacheEntity.h"

NSString *const kFUZDefaultScheme = @"http";
NSInteger const kHTTPPartialRequestSuccessCode = 206;
NSInteger const kHTTPNotModifiedSuccessCode = 304;

@interface FUZLoadingOperation () <NSURLConnectionDelegate>

@property (nonatomic, assign, getter=isFinished) BOOL finished;
@property (nonatomic, assign, getter=isExecuting) BOOL executing;

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSHTTPURLResponse *response;

@property (nonatomic, assign) NSRange requiredRange;
@property (nonatomic, assign) NSInteger currentLocation;

@property (nonatomic, assign, getter=isContentInfoRequest) BOOL contentInfoRequest;

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
    
    self.executing = YES;

    BOOL canReadFromCache = [self.cache canReadFromCacheWithOffset:self.currentLocation];
    if(canReadFromCache && !self.isContentInfoRequest)
    {
        [self receiveDataFromCache];
    }
    else
    {
        [self receiveDataFromNetwork];
    }
}

- (void)finish
{
    if(self.connection)
    {
        [self.connection cancel];
        self.connection = nil;
    }
    self.executing = NO;
    self.finished = YES;
}

#pragma mark - Methods

- (void)receiveDataFromCache
{
    if(self.isContentInfoRequest)
    {
        NSDictionary *cachedHeaders = [self.cache copyResponseFromCache].allHeaderFields;
        [self setupContentInformationRequestWithResponseHeaders:cachedHeaders];
    }
    
    @weakify(self);
    [self.cache readFromCacheFromOffset:self.requiredRange.location withLength:self.requiredRange.length cacheBlock:^(NSData *cacheBlock)
     {
         @strongify(self);
         if(self.isCancelled)
         {
             [self finish];
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
    [self finish];
}

- (void)receiveDataFromNetwork
{
    NSMutableURLRequest *request = [self.resourceLoadingRequest.request mutableCopy];
    NSLog(@"%@", request.allHTTPHeaderFields);
    
    request.URL = [request.URL fuz_urlWithScheme:kFUZDefaultScheme];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
    [self.connection start];
}

- (void)setupContentInformationRequestWithResponseHeaders:(NSDictionary *)headers
{
    self.resourceLoadingRequest.contentInformationRequest.contentType = [headers fuz_responseUTIFromContentTypeValue];
    self.resourceLoadingRequest.contentInformationRequest.contentLength = [headers fuz_responseContentRangeTotalLength];
    self.resourceLoadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
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
    self.contentInfoRequest = (self.resourceLoadingRequest.contentInformationRequest != nil);
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    NSLog(@"%@", response);
    self.response = response;
    NSDictionary *headers = response.allHeaderFields;
    
    if(self.isContentInfoRequest && response.statusCode == kHTTPPartialRequestSuccessCode)
    {
        [self setupContentInformationRequestWithResponseHeaders:response.allHeaderFields];
        [self.cache writeResponseToCache:response];
    }
    if(response.statusCode == kHTTPNotModifiedSuccessCode)
    {
        
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if(self.isCancelled)
    {
        [self finish];
        return;
    }
    
    if(!self.isContentInfoRequest)
    {
        //Cache only data request
        [self.cache writeDataToCache:data withOffset:self.currentLocation];
        self.currentLocation += data.length;
    }
    [self.resourceLoadingRequest.dataRequest respondWithData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self.resourceLoadingRequest finishLoading];
    [self finish];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.resourceLoadingRequest finishLoadingWithError:error];
    [self finish];
}

@end
