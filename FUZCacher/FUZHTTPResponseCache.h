//
//  FUZHTTPResponceCache.h
//  FUZCacher
//
//  Created by fuzza on 7/17/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FUZCachedChunk.h"

typedef void(^FUZHTTPResponseCacheBlock)(NSData *cacheBlock, BOOL isLastBlock, NSInteger totalCachedLength);

@interface FUZHTTPResponseCache : NSObject

+ (instancetype)sharedCache;
- (void)writeDataToCache:(NSData *)data withOffset:(NSInteger)offset;
- (BOOL)canReadFromCacheWithOffset:(NSInteger)offset;
- (void)readFromCacheFromOffset:(NSInteger)offset withLength:(NSInteger)length cacheBlock:(FUZHTTPResponseCacheBlock)block;

@end
