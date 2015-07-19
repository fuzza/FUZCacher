//
//  FUZFileSystemService.m
//  FUZCacher
//
//  Created by fuzza on 7/18/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import "FUZFileHandle.h"

@interface FUZFileHandle ()

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSFileHandle *writeHandle;
@property (nonatomic, strong) NSFileHandle *readHandle;

@end

@implementation FUZFileHandle

- (instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    if(self)
    {
        _path = path;
        [self setupWriteHandle];
        [self setupReadHandle];
    }
    return self;
}

- (void)dealloc
{
    [self.writeHandle closeFile];
    [self.readHandle closeFile];
}

- (void)setupWriteHandle
{
    self.writeHandle = [NSFileHandle fileHandleForWritingAtPath:self.path];
    if(self.writeHandle == nil)
    {
        [[NSFileManager defaultManager] createFileAtPath:self.path contents:nil attributes:nil];
        self.writeHandle = [NSFileHandle fileHandleForWritingAtPath:self.path];
    }
}

- (void)setupReadHandle
{
    NSError *handleError;
    self.readHandle = [NSFileHandle fileHandleForReadingFromURL:[NSURL URLWithString:self.path] error:&handleError];
}

- (void)writeData:(NSData *)data
       withOffset:(NSInteger)offset
{
    if(!self.writeHandle)
    {
        return;
    }
    [self.writeHandle seekToFileOffset:offset];
    [self.writeHandle writeData:data];
}

- (void)readDataFromStartOffset:(NSInteger)startOffset
                         length:(NSInteger)length
                      blockSize:(NSInteger)blockSize
                   dataCallback:(FUZFileBlockReadingCallback)callback
{
    if(!self.readHandle)
    {
        return;
    }
    
    [self.readHandle seekToFileOffset:startOffset];

    NSInteger remainingLength = length;
    do
    {
        NSData *block = nil;
        if(remainingLength < blockSize)
        {
            block = [self.readHandle readDataOfLength:remainingLength];
            remainingLength-=remainingLength;
        }
        else
        {
            block = [self.readHandle readDataOfLength:blockSize];
            remainingLength-=blockSize;
        }
        
        if(block.length)
        {
            callback(block);
        }
    }
    while (remainingLength > 0);
}

@end
