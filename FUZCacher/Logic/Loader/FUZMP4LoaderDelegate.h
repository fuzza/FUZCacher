//
//  FUZMP4LoaderDelegate.h
//  FUZCacher
//
//  Created by fuzza on 7/19/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FUZCacheEntity;

@interface FUZMP4LoaderDelegate : NSObject <AVAssetResourceLoaderDelegate>

- (void)setupWithCache:(FUZCacheEntity *)cache;
- (void)invalidateCache;
- (void)cancelLoading;


@end
