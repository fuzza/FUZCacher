//
//  FUZFileHandleSpec.m
//  FUZCacher
//
//  Created by fuzza on 7/19/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import "FUZFileHandle.h"

@interface FUZFileHandle (Testing)

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSFileHandle *writeHandle;
@property (nonatomic, strong) NSFileHandle *readHandle;

- (void)setupWriteHandle;
- (void)setupReadHandle;

@end

SpecBegin(FUZFileHandle)

describe(@"initWithPath", ^()
{
    it(@"should return nil if nil path passed", ^()
    {
        FUZFileHandle *sut = [[FUZFileHandle alloc] initWithPath:nil];
        XCTAssertNil(sut);
    });
    
    it(@"should fill path", ^()
    {
        FUZFileHandle *sut = [[FUZFileHandle alloc] initWithPath:@"some_test_path"];
        EXP_expect(sut.path).equal(@"some_test_path");
    });
});

describe(@"open", ^()
{
    it(@"should call setup methods for NSFileHandlers", ^()
    {
        FUZFileHandle *sut = [[FUZFileHandle alloc] init];
        id partialSut = OCMPartialMock(sut);
        [[partialSut expect] setupWriteHandle];
        [[partialSut expect] setupReadHandle];
        
        [sut open];
        
        [partialSut verify];
    });
});

SpecEnd