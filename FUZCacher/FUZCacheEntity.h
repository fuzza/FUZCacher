//
//  FUZHTTPResponceCache.h
//  FUZCacher
//
//  Created by fuzza on 7/17/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^FUZHTTPResponseCacheBlock)(NSData *cacheBlock);

@interface FUZCacheEntity : NSObject <NSCoding>

- (instancetype)initWithURL:(NSURL *)url;

- (void)writeResponseToCache:(NSHTTPURLResponse *)response;
- (NSHTTPURLResponse *)copyResponseFromCache;

- (void)writeDataToCache:(NSData *)data withOffset:(NSInteger)offset;
- (BOOL)canReadFromCacheWithOffset:(NSInteger)offset;
- (void)readFromCacheFromOffset:(NSInteger)offset withLength:(NSInteger)length cacheBlock:(FUZHTTPResponseCacheBlock)block;

@end
