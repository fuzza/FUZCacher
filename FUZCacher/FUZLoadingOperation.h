//
//  FUZLoadingOperation.h
//  FUZCacher
//
//  Created by fuzza on 7/18/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FUZCacheEntity;

@interface FUZLoadingOperation : NSOperation

@property (nonatomic, strong) AVAssetResourceLoadingRequest *resourceLoadingRequest;
@property (nonatomic, strong) FUZCacheEntity *cache;

@end
