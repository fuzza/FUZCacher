//
//  FUZCache.h
//  FUZCacher
//
//  Created by fuzza on 7/19/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FUZCacheEntity;

@interface FUZCache : NSObject

- (BOOL)isCacheExistsForURL:(NSURL *)url;
- (FUZCacheEntity *)cacheEntityForURL:(NSURL *)url;
- (void)saveCacheToPersistentStorage;

@end
