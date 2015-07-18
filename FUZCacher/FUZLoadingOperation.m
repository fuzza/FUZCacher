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

@property (nonatomic, strong) FUZCachedChunk *cachedChunk;

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *receivedData;

@property (nonatomic, assign, getter=isFinished) BOOL finished;
@property (nonatomic, assign, getter=isExecuting) BOOL executing;

@property (nonatomic, assign) NSInteger dataOffset;

@property (nonatomic, assign) BOOL disableCaching;

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
    
    self.finished = NO;
    self.executing = YES;
    
    NSMutableURLRequest *request = [self.resourceLoadingRequest.request mutableCopy];
    request.URL = [request.URL fuz_urlWithScheme:kFUZDefaultScheme];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    if(self.resourceLoadingRequest.contentInformationRequest)
    {
        self.disableCaching = YES;
    }
    
    NSLog(@"%@", self.resourceLoadingRequest);
    NSLog(@"%@", request.allHTTPHeaderFields);
    
    self.dataOffset = self.resourceLoadingRequest.dataRequest.currentOffset;
    
    if([[FUZHTTPResponseCache sharedCache] canReadFromCacheWithOffset:self.dataOffset])
    {
        self.resourceLoadingRequest.contentInformationRequest.contentType = (__bridge NSString *)(kUTTypeMPEG4);
        self.resourceLoadingRequest.contentInformationRequest.contentLength = 21042737;
        self.resourceLoadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
        
        NSLog(@"Reading cache from offset %ld", (long)self.dataOffset);
        [[FUZHTTPResponseCache sharedCache] readFromCacheFromOffset:self.dataOffset withLength:self.resourceLoadingRequest.dataRequest.requestedLength cacheBlock:^(NSData *cachedData, BOOL isLastBlock, NSInteger totalCachedLength)
        {
            [self.resourceLoadingRequest.dataRequest respondWithData:cachedData];
            
            if(isLastBlock)
            {
                if(totalCachedLength < self.resourceLoadingRequest.dataRequest.requestedLength)
                {
                    NSString *modifiedRangeHeader = [NSString stringWithFormat:@"bytes=%lld-%lld", self.resourceLoadingRequest.dataRequest.requestedOffset+totalCachedLength, self.resourceLoadingRequest.dataRequest.requestedOffset + self.resourceLoadingRequest.dataRequest.requestedLength];
                    
                    [request setValue:modifiedRangeHeader forHTTPHeaderField:@"Range"];
                    NSLog(@"Cache reading ended, started request with Modified headers%@", request.allHTTPHeaderFields);
                    
                    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
                    [self.connection start];
                    return;
                }
                else
                {
                    [self.resourceLoadingRequest finishLoading];
                    self.executing = NO;
                    self.finished = YES;
                    return;
                }
            }
        }];
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

#pragma mark - Accessors/Mutators

- (NSMutableData *)receivedData
{
    if(!_receivedData)
    {
        _receivedData = [[NSMutableData alloc] init];
    }
    return _receivedData;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    NSLog(@"%@", response);
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
        [self.connection cancel];
        self.connection = nil;
        self.executing = NO;
        self.finished = YES;
    }
    
    if(!self.disableCaching)
    {
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
    
    self.executing = NO;
    self.finished = YES;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^()
                   {
                       [self.resourceLoadingRequest finishLoadingWithError:error];
                   });
    
    
    self.executing = NO;
    self.finished = YES;
}

@end
