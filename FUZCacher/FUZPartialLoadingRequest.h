//
//  FUZPartialLoadingRequest.h
//  FUZCacher
//
//  Created by fuzza on 7/19/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FUZPartialLoadingRequest : NSObject

- (void)setupWithResourceLoadingRequest:(AVAssetResourceLoadingRequest *)resourceLoaderRequest;
- (BOOL)conformsToResourceLoadingRequest:(AVAssetResourceLoadingRequest *)request;

- (void)fillWithResponseHeaders:(NSDictionary *)headers;
- (void)fillWithData:(NSData *)data;
- (void)finishWithError:(NSError *)error;

- (NSInteger)requiredOffset;
- (NSInteger)requiredLength;
- (NSInteger)currentLocation;

- (BOOL)isMetadataRequest;
- (NSMutableURLRequest *)httpRequest;

@end
