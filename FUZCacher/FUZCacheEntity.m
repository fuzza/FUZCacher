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
        NSString *relativePath = [aDecoder decodeObjectForKey:kFUZCacheFilePathKey];
        if(relativePath)
        {
            self.filePath = [self absolutePathFromRelative:relativePath];
        }
        
        if([FUZFileHandle fileExistsAtPath:self.filePath])
        {
            self.ranges = [aDecoder decodeObjectForKey:kFUZCacheEntityRangesKey];
        }
    }
    
    return self;
}

- (void)invalidate
{
    [self.fileHandle invalidate];
    self.cachedResponse = nil;
    self.ranges = nil;
    self.fileHandle = [[FUZFileHandle alloc] initWithPath:self.filePath];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.url forKey:kFUZCacheEntityURLKey];
    [aCoder encodeObject:self.cachedResponse forKey:kFUZCacheEntityResponseKey];
    [aCoder encodeObject:[self.filePath lastPathComponent] forKey:kFUZCacheFilePathKey];
    [aCoder encodeObject:self.ranges forKey:kFUZCacheEntityRangesKey];
}

- (NSString *)absolutePathFromRelative:(NSString *)relativePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:relativePath];
}

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    if(self)
    {
        self.url = url;
        [self generateFilePath];
    }
    return self;
}

- (void)generateFilePath
{
    NSString *extension = [self.url pathExtension];
    NSString *fileName = [[NSUUID UUID] UUIDString];
    NSString *relativePath = [fileName stringByAppendingPathExtension:extension];
    self.filePath = [self absolutePathFromRelative:relativePath];
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
    for (NSString *rangeString in self.ranges)
    {
        NSRange cachedRange = NSRangeFromString(rangeString);
        NSRange intersection = NSIntersectionRange(cachedRange, targetRange);
        
        BOOL shouldBeMerged = (cachedRange.location + cachedRange.length == targetRange.location);
        shouldBeMerged = shouldBeMerged || (targetRange.location + targetRange.length == cachedRange.location);
        
        if (intersection.length > 0 || shouldBeMerged)
        {
            NSRange unionRange = NSUnionRange(cachedRange, targetRange);
            [self.ranges removeObject:rangeString];
            [self.ranges addObject:NSStringFromRange(unionRange)];
            NSLog(@"Merged ranges to %@", NSStringFromRange(unionRange));
            merged = YES;
            break;
        }
    }
    
    if(!merged)
    {
        NSLog(@"Added rangee to %@", NSStringFromRange(targetRange));
        [self.ranges addObject:NSStringFromRange(targetRange)];
    }
}

- (void)readFromCacheFromOffset:(NSInteger)offset withLength:(NSInteger)length cacheBlock:(FUZHTTPResponseCacheBlock)block
{
    NSRange targetRange = NSMakeRange(offset, length);
    NSRange __block intersection;
    for (NSString *rangeString in self.ranges)
    {
        NSRange cachedRange = NSRangeFromString(rangeString);
        NSRange matched = NSIntersectionRange(cachedRange, targetRange);
        if (matched.length > 0 && matched.location == targetRange.location)
        {
            intersection = matched;
            break;
        }
    }

    [self.fileHandle readDataFromStartOffset:intersection.location length:intersection.length blockSize:1024 dataCallback:^(NSData *chunk, BOOL *stop)
    {
        block(chunk, stop);
    }];
}

- (BOOL)canReadFromCacheWithOffset:(NSInteger)offset
{
    NSRange targetRange = NSMakeRange(offset, 1);
    for (NSString *rangeString in self.ranges)
    {
        NSRange cachedRange = NSRangeFromString(rangeString);
        NSRange intersection = NSIntersectionRange(cachedRange, targetRange);
        if (intersection.length > 0)
        {
            return YES;
        }
    }
    return NO;
}

- (FUZFileHandle *)fileHandle
{
    if(!_fileHandle)
    {
        _fileHandle = [[FUZFileHandle alloc] initWithPath:self.filePath];
    }
    return _fileHandle;
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
