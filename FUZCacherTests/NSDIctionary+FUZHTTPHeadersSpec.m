//
//  NSDIctionary+FUZHTTPHeadersSpec.m
//  FUZCacher
//
//  Created by fuzza on 7/19/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import "NSDictionary+FUZHTTPHeaders.h"

SpecBegin(NSDictionary)

describe(@"fuz_requestBytesRangeValue", ^()
{
    it(@"should return zero range if no header found", ^()
    {
        NSDictionary *sut = @{};
        NSRange sutRange = [sut fuz_requestBytesRangeValue];
        XCTAssertTrue(NSEqualRanges(sutRange, NSMakeRange(0, 0)));
    });
    
    it(@"should return zero range if incorrect header is passed", ^()
    {
        NSDictionary *sut = @{@"Range" : @"bytes=1+15"};
        NSRange sutRange = [sut fuz_requestBytesRangeValue];
        
        EXP_expect(NSEqualRanges(sutRange, NSMakeRange(0, 0)));
    });
    
    it(@"should return correct NSRange from range header", ^()
    {
        NSDictionary *sut = @{@"Range" : @"bytes=1-15"};
        NSRange sutRange = [sut fuz_requestBytesRangeValue];
        
        EXP_expect(NSEqualRanges(sutRange, NSMakeRange(1, 15)));
    });
});

describe(@"fuz_responseContentRangeTotalLength", ^()
{
    it(@"should return zero if no header found", ^()
    {
        NSDictionary *sut = @{};
        NSInteger sutLength = [sut fuz_responseContentRangeTotalLength];
        EXP_expect(sutLength).equal(0);
    });
    
    it(@"should return content lenght from content-range header", ^()
    {
        NSDictionary *sut = @{@"Content-Range" : @"bytes=1-15/25"};
        NSInteger sutLength = [sut fuz_responseContentRangeTotalLength];
        EXP_expect(sutLength).equal(25);
    });
});

describe(@"fuz_responseUTIFromContentTypeValue", ^()
{
    it(@"should return nil if no header found", ^()
    {
        NSDictionary *sut = @{};
        NSInteger sutLength = [sut fuz_responseContentRangeTotalLength];
        EXP_expect(sutLength).equal(0);
    });
    
    it(@"should return correct UTI for mp4", ^()
    {
        NSDictionary *sut = @{@"Content-Type" : @"video/mp4"};
        NSString *uti = [sut fuz_responseUTIFromContentTypeValue];
        EXP_expect(uti).equal(@"public.mpeg-4");
    });
});

describe(@"fuz_responseLastModifiedValue", ^()
{
    it(@"should return nil if no header found", ^()
    {
        NSDictionary *sut = @{@"Last-Modified" : @"22.05.15"};
        NSString *lastModified = [sut fuz_responseLastModifiedValue];
        EXP_expect(lastModified).equal(@"22.05.15");
    });
});


SpecEnd
