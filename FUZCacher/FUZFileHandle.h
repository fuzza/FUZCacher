//
//  FUZFileSystemService.h
//  FUZCacher
//
//  Created by fuzza on 7/18/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^FUZFileBlockReadingCallback)(NSData *block);

@interface FUZFileHandle : NSObject

- (instancetype)initWithPath:(NSString *)path;

- (void)writeData:(NSData *)data
       withOffset:(NSInteger)offset;

- (void)readDataFromStartOffset:(NSInteger)startOffset
                         length:(NSInteger)length
                      blockSize:(NSInteger)blockSize
                   dataCallback:(FUZFileBlockReadingCallback)callback;

@end
