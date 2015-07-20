//
//  FUZMP4LoaderDelegate.m
//  FUZCacher
//
//  Created by fuzza on 7/19/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import "FUZMP4LoaderDelegate.h"
#import "FUZLoadingOperation.h"
#import "FUZCacheEntity.h"
#import "FUZPartialLoadingRequest.h"

@interface FUZMP4LoaderDelegate ()

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) FUZLoadingOperation *currentLoadingOperation;
@property (nonatomic, strong) FUZCacheEntity *cache;

@end

@implementation FUZMP4LoaderDelegate

- (void)setupWithCache:(FUZCacheEntity *)cache
{
    self.cache = cache;
}

- (void)invalidateCache
{
    [self.cache invalidate];
}

- (void)cancelLoading
{
    [self.operationQueue cancelAllOperations];
}

- (NSOperationQueue *)operationQueue
{
    if(!_operationQueue)
    {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
    }
    return _operationQueue;
}

#pragma mark - AVAssetResourceLoaderDelegate

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [self.currentLoadingOperation cancel];
    
    FUZPartialLoadingRequest *partialRequest = [FUZPartialLoadingRequest new];
    [partialRequest setupWithResourceLoadingRequest:loadingRequest];
    
    self.currentLoadingOperation = [FUZLoadingOperation new];
    self.currentLoadingOperation.cache = self.cache;
    self.currentLoadingOperation.loadingRequest = partialRequest;
    
    [self.operationQueue addOperation:self.currentLoadingOperation];
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    for(FUZLoadingOperation *op in self.operationQueue.operations)
    {
        if([op.loadingRequest conformsToResourceLoadingRequest:loadingRequest])
        {
            [op cancel];
        }
    }
}

@end
