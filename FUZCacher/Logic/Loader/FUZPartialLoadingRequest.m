//
//  FUZPartialLoadingRequest.m
//  FUZCacher
//
//  Created by fuzza on 7/19/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import "FUZPartialLoadingRequest.h"
#import "NSDictionary+FUZHTTPHeaders.h"
#import "NSURL+FUZScheme.h"

NSString *const kFUZDefaultScheme = @"http";

@interface FUZPartialLoadingRequest ()

@property (nonatomic, strong) AVAssetResourceLoadingRequest *loadingRequest;
@property (nonatomic, assign) NSInteger currentLocation;

@end

@implementation FUZPartialLoadingRequest

- (void)setupWithResourceLoadingRequest:(AVAssetResourceLoadingRequest *)resourceLoaderRequest
{
    NSLog(@"%@",resourceLoaderRequest);
    self.loadingRequest = resourceLoaderRequest;
    self.currentLocation = self.loadingRequest.dataRequest.requestedOffset;
}

- (BOOL)conformsToResourceLoadingRequest:(AVAssetResourceLoadingRequest *)request
{
    return self.loadingRequest == request;
}

- (void)fillWithResponseHeaders:(NSDictionary *)headers
{
    self.loadingRequest.contentInformationRequest.contentType = [headers fuz_responseUTIFromContentTypeValue];
    self.loadingRequest.contentInformationRequest.contentLength = [headers fuz_responseContentRangeTotalLength];
    self.loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
}

- (void)fillWithData:(NSData *)data
{
    [self.loadingRequest.dataRequest respondWithData:data];
    self.currentLocation += data.length;
}

- (void)finishWithError:(NSError *)error
{
    if(self.loadingRequest.isFinished)
    {
        return;
    }
    
    if(error)
    {
        [self.loadingRequest finishLoadingWithError:error];
        return;
    }
    [self.loadingRequest finishLoading];
}

#pragma mark - Stream position

- (NSInteger)requiredOffset
{
    return self.loadingRequest.dataRequest.requestedOffset;
}

- (NSInteger)requiredLength
{
    return self.loadingRequest.dataRequest.requestedLength;
}

- (NSInteger)currentLocation
{
    return _currentLocation;
}

#pragma mark - Networking

- (BOOL)isMetadataRequest
{
    return (self.loadingRequest.contentInformationRequest != nil);
}

- (NSMutableURLRequest *)httpRequest
{
    NSMutableURLRequest *request = [self.loadingRequest.request mutableCopy];
    request.URL = [request.URL fuz_urlWithScheme:kFUZDefaultScheme];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    return request;
}

@end
