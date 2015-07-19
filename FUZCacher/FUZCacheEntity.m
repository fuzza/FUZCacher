//
//  FUZHTTPResponceCache.m
//  FUZCacher
//
//  Created by fuzza on 7/17/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import "FUZCacheEntity.h"
#import "FUZFileHandle.h"

NSString *const kFUZCacheEntityURLKey = @"kFUZCacheEntityURLKey";
NSString *const kFUZCacheEntityResponseKey = @"kFUZCacheEntityResponseKey";
NSString *const kFUZCacheFilePathKey = @"kFUZCacheFilePathKey";
NSString *const kFUZCacheEntityRangesKey = @"kFUZCacheEntityRangesKey";

@interface FUZCacheEntity ()

@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSHTTPURLResponse *cachedResponse;
@property (nonatomic, strong) NSMutableArray *ranges;
@property (nonatomic, strong) NSString *filePath;

@property (nonatomic, strong) FUZFileHandle *fileHandle;

@end

@implementation FUZCacheEntity

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self)
    {
        self.url = [aDecoder decodeObjectForKey:kFUZCacheEntityURLKey];
        self.cachedResponse = [aDecoder decodeObjectForKey:kFUZCacheEntityResponseKey];
        self.filePath = [aDecoder decodeObjectForKey:kFUZCacheFilePathKey];
        
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.url forKey:@"urlKey"];
    [aCoder encodeObject:self.cachedResponse forKey:@"cachedResponse"];
    [aCoder encodeObject:self.filePath forKey:@"filePath"];
    
    
    NSMutableArray *rangesToEncode = [@[] mutableCopy];
    for (NSValue *rangeValue in self.ranges)
    {
        NSRange range = [rangeValue rangeValue];
        [rangesToEncode addObject:NSStringFromRange(range)];
    }
    [aCoder encodeObject:rangesToEncode forKey:@"ranges"];
}

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    if(self)
    {
        self.url = url;
        [self generateFilePath];
        [self openFileHandle];
    }
    return self;
}

- (void)generateFilePath
{
    NSString *extension = [self.url pathExtension];
    NSString *fileName = [[NSUUID UUID] UUIDString];
    NSString *fullPath = [fileName stringByAppendingPathExtension:extension];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    self.filePath = [documentsDirectory stringByAppendingPathComponent:fullPath];
}

- (void)openFileHandle
{
    self.fileHandle = [[FUZFileHandle alloc] initWithPath:self.filePath];
}

- (void)writeResponseToCache:(NSHTTPURLResponse *)response
{
    self.cachedResponse = response;
}

- (NSHTTPURLResponse *)copyResponseFromCache
{
    return [self.cachedResponse copy];
}

- (void)writeDataToCache:(NSData *)data withOffset:(NSInteger)offset
{
    [self.fileHandle writeData:data
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

    [self.fileHandle readDataFromStartOffset:intersection.location length:intersection.length blockSize:1024 dataCallback:^(NSData *chunk)
    {
        block(chunk);
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
