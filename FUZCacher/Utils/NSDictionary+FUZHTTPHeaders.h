//
//  NSDictionary+FUZHTTPHeaders.h
//  FUZCacher
//
//  Created by fuzza on 7/18/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kRequestHeaderRangeKey;
extern NSString * const kIfModifiedSinceHeaderKey;
extern NSString * const kContentRangeHeaderKey;
extern NSString * const kContentTypeHeaderKey;
extern NSString * const kLastModifiedHeaderKey;

@interface NSDictionary (FUZHTTPHeaders)

- (NSRange)fuz_requestBytesRangeValue;

- (NSInteger)fuz_responseContentRangeTotalLength;
- (NSString *)fuz_responseUTIFromContentTypeValue;
- (NSString *)fuz_responseLastModifiedValue;

@end
