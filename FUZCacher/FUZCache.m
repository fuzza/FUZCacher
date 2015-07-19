//
//  FUZCache.m
//  FUZCacher
//
//  Created by fuzza on 7/19/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import "FUZCache.h"
#import "FUZCacheEntity.h"

@interface FUZCache ()

@property (nonatomic, strong) NSCache *cache;

@end

@implementation FUZCache

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        [self loadCacheFromPersistentStorageOrCreateNew];
    }
    return self;
}

- (void)loadCacheFromPersistentStorageOrCreateNew
{
    NSData *unarchivedCache = [[NSUserDefaults standardUserDefaults] objectForKey:@"FUZCacheKey"];
    if(unarchivedCache)
    {
        self.cache = [NSKeyedUnarchiver unarchiveObjectWithData:[NSData new]];
        return;
    }
    self.cache = [[NSCache alloc] init];
}

- (void)saveCacheToPersistentStorage
{
    NSData *archivedCacheData = [NSKeyedArchiver archivedDataWithRootObject:self.cache];
    [[NSUserDefaults standardUserDefaults] setObject:archivedCacheData forKey:@"FUZCacheKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isCacheExistsForURL:(NSURL *)url
{
    return ([self.cache objectForKey:url] != nil);
}

- (FUZCacheEntity *)cacheEntityForURL:(NSURL *)url
{
    FUZCacheEntity *cacheEntity = [self.cache objectForKey:url];
    if(!cacheEntity)
    {
        cacheEntity = [[FUZCacheEntity alloc] initWithURL:url];
    }
    [self.cache setObject:cacheEntity forKey:url];
    return cacheEntity;
}

@end
