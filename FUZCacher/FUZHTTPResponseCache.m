//
//  FUZHTTPResponceCache.m
//  FUZCacher
//
//  Created by fuzza on 7/17/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import "FUZHTTPResponseCache.h"

@interface FUZHTTPResponseCache ()

@property (nonatomic, strong) NSMutableArray *chunks;
@property (nonatomic, strong) NSMutableArray *ranges;

@end

@implementation FUZHTTPResponseCache

+ (instancetype)sharedCache
{
    static FUZHTTPResponseCache *sharedCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^(){
        sharedCache = [FUZHTTPResponseCache new];
    });
    return sharedCache;
}

- (void)writeDataToCache:(NSData *)data withOffset:(NSInteger)offset
{
    for(FUZCachedChunk *chunk in self.chunks)
    {
        if(chunk.startOffset == offset)
        {
            [self.chunks removeObject:chunk];
            break;
        }
        
        if(chunk.startOffset+chunk.length == offset)
        {
            [chunk.data appendData:data];
            chunk.length+=data.length;
            return;
        }
    }
    
    FUZCachedChunk *newChunk = [[FUZCachedChunk alloc] init];
    [newChunk.data appendData:data];
    newChunk.startOffset = offset;
    newChunk.length = data.length;
    
    [self.chunks addObject:newChunk];
}

- (void)readFromCacheFromOffset:(NSInteger)offset withLength:(NSInteger)length cacheBlock:(FUZHTTPResponseCacheBlock)block
{
    for(FUZCachedChunk *chunk in self.chunks)
    {
        if([chunk containsLocation:offset])
        {
            NSData *cachedLocalData = nil;
            
            NSInteger localOffset = offset - chunk.startOffset;
            NSInteger remainingChunkLength = chunk.data.length - localOffset;
            if(remainingChunkLength <= length)
            {
                cachedLocalData = [chunk.data subdataWithRange:NSMakeRange(localOffset, remainingChunkLength)];
            }
            else
            {
                cachedLocalData = [chunk.data subdataWithRange:NSMakeRange(localOffset, length)];
            }
            
            NSInteger blockSize = 14061;
            NSInteger blockOffset = 0;
            
            NSData *subdata = cachedLocalData;
            while (cachedLocalData.length - blockOffset > blockSize)
            {
                subdata = [cachedLocalData subdataWithRange:NSMakeRange(blockOffset, blockSize)];
                blockOffset+=blockSize;
                block(subdata, NO, blockOffset);
            }
            subdata = [cachedLocalData subdataWithRange:NSMakeRange(blockOffset, cachedLocalData.length - blockOffset)];
            block(subdata, YES, cachedLocalData.length);
            return;
        }
    }
}

- (BOOL)canReadFromCacheWithOffset:(NSInteger)offset
{
    for(FUZCachedChunk *chunk in self.chunks)
    {
        if([chunk containsLocation:offset])
        {
            return YES;
        }
    }
    return NO;
}

- (NSMutableArray *)chunks
{
    if(!_chunks)
    {
        _chunks = [@[] mutableCopy];
    }
    return _chunks;
}

- (NSMutableArray *)ranges
{
    if(!_ranges)
    {
        _ranges = [@[] mutableCopy];
    }
    return _ranges;
}

@end
