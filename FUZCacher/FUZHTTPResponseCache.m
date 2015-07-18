//
//  FUZHTTPResponceCache.m
//  FUZCacher
//
//  Created by fuzza on 7/17/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import "FUZHTTPResponseCache.h"
#import "FUZFileSystemService.h"

@interface FUZHTTPResponseCache ()



@property (nonatomic, strong) NSMutableArray *ranges;
@property (nonatomic, strong) FUZFileSystemService *file;

@end

@implementation FUZHTTPResponseCache

+ (instancetype)sharedCache
{
    static FUZHTTPResponseCache *sharedCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^(){
        sharedCache = [FUZHTTPResponseCache new];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"test.mp4"];
        sharedCache.file = [[FUZFileSystemService alloc] initWithPath:filePath];
        
    });
    return sharedCache;
}

- (void)writeDataToCache:(NSData *)data withOffset:(NSInteger)offset
{
    [self.file writeData:data
              withOffset:offset];
    
    NSRange targetRange = NSMakeRange(offset, data.length);
    
    BOOL merged = NO;
    for (NSValue *rangeValue in self.ranges)
    {
        NSRange cachedRange = [rangeValue rangeValue];
        NSRange intersection = NSIntersectionRange(cachedRange, targetRange);
        
        BOOL shouldBeMerged = (cachedRange.location + cachedRange.length == targetRange.location);
        shouldBeMerged = shouldBeMerged || (targetRange.location + targetRange.length == cachedRange.location);
        
        if (intersection.length > 0 || shouldBeMerged)
        {
            NSRange unionRange = NSUnionRange(cachedRange, targetRange);
            [self.ranges removeObject:rangeValue];
            [self.ranges addObject:[NSValue valueWithRange:unionRange]];
            NSLog(@"Merged ranges to %@", NSStringFromRange(unionRange));
            merged = YES;
            break;
        }
    }
    
    if(!merged)
    {
        NSLog(@"Added rangee to %@", NSStringFromRange(targetRange));
        [self.ranges addObject:[NSValue valueWithRange:targetRange]];
    }
}

- (void)readFromCacheFromOffset:(NSInteger)offset withLength:(NSInteger)length cacheBlock:(FUZHTTPResponseCacheBlock)block
{
    NSRange targetRange = NSMakeRange(offset, length);
    NSRange __block intersection;
    for (NSValue *rangeValue in self.ranges)
    {
        NSRange cachedRange = [rangeValue rangeValue];
        NSRange matched = NSIntersectionRange(cachedRange, targetRange);
        if (matched.length > 0 && matched.location == targetRange.location)
        {
            intersection = matched;
            break;
        }
    }

    [self.file readDataFromStartOffset:intersection.location length:intersection.length blockSize:1024 dataCallback:^(NSData *chunk)
    {
        block(chunk, NO, 0);
    }];
}

- (BOOL)canReadFromCacheWithOffset:(NSInteger)offset
{
    NSRange targetRange = NSMakeRange(offset, 1);
    for (NSValue *rangeValue in self.ranges)
    {
        NSRange cachedRange = [rangeValue rangeValue];
        NSRange intersection = NSIntersectionRange(cachedRange, targetRange);
        if (intersection.length > 0)
        {
            return YES;
        }
    }
    return NO;
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
