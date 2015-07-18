//
//  FUZCachedChunk.h
//  FUZCacher
//
//  Created by fuzza on 7/18/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FUZCachedChunk : NSObject

@property (nonatomic, assign) NSInteger startOffset;
@property (nonatomic, assign) NSInteger length;

@property (nonatomic, strong) NSMutableData *data;

- (BOOL)containsLocation:(NSInteger)location;

@end
