//
//  FUZPartialLoadingRequestSpec.m
//  FUZCacher
//
//  Created by Alexey Fayzullov on 7/20/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "FUZPartialLoadingRequest.h"
#import "NSDictionary+FUZHTTPHeaders.h"

@interface FUZPartialLoadingRequest (Testing)

@property (nonatomic, strong) AVAssetResourceLoadingRequest *loadingRequest;
@property (nonatomic, assign) NSInteger currentLocation;

@end

SpecBegin(FUZPartialLoadingRequest)

FUZPartialLoadingRequest __block *sut;
id __block requestMock;
id __block dataRequestMock;
id __block contentRequestMock;

beforeEach(^()
{
    sut = [FUZPartialLoadingRequest new];
    requestMock = OCMClassMock([AVAssetResourceLoadingRequest class]);
    dataRequestMock = OCMClassMock([AVAssetResourceLoadingDataRequest class]);
    contentRequestMock = OCMClassMock([AVAssetResourceLoadingContentInformationRequest class]);

    [[[requestMock stub] andReturn:dataRequestMock] dataRequest];
    [[[requestMock stub] andReturn:contentRequestMock] contentInformationRequest];
});

afterEach(^()
{
    [requestMock stopMocking];
    [dataRequestMock stopMocking];
    [contentRequestMock stopMocking];
    
    sut = nil;
    requestMock = nil;
    dataRequestMock = nil;
    contentRequestMock = nil;
});

describe(@"setupWithResourceLoadingRequest:", ^()
{
    it(@"should set loading request and currentOffset from param", ^()
    {
        [sut setupWithResourceLoadingRequest:requestMock];
        XCTAssertEqualObjects(sut.loadingRequest, requestMock);
    });
    
    it(@"should set current location from data request", ^()
    {
        [[[dataRequestMock stub] andReturnValue:OCMOCK_VALUE(12345)] requestedOffset];
        
        [sut setupWithResourceLoadingRequest:requestMock];
        EXP_expect(sut.currentLocation).equal(12345);
        
        [requestMock stopMocking];
        [dataRequestMock stopMocking];
    });
});

describe(@"conformsToResourceLoadingRequest:", ^()
{
    it(@"should return true if param is equal to sut.loadingRequest", ^()
    {
        sut.loadingRequest = requestMock;
        BOOL result = [sut conformsToResourceLoadingRequest:requestMock];
        XCTAssertTrue(result);
    });
    
    it(@"should return false if param not equal to sut.loadingRequest", ^()
    {
        id anotherRequestMock = OCMClassMock([AVAssetResourceLoadingRequest class]);
        sut.loadingRequest = requestMock;
        BOOL result = [sut conformsToResourceLoadingRequest:anotherRequestMock];
        XCTAssertFalse(result);
    });
});

describe(@"fillWithResponseHeaders:", ^()
{
    it(@"should set values from headers to contentRequest", ^()
    {
        id headersMock = OCMClassMock([NSDictionary class]);
        [[[headersMock stub] andReturnValue:OCMOCK_VALUE(252525)] fuz_responseContentRangeTotalLength];
        [[[headersMock stub] andReturn:@"testContentType"] fuz_responseUTIFromContentTypeValue];
        
        [[contentRequestMock expect] setContentLength:252525];
        [[contentRequestMock expect] setContentType:@"testContentType"];
        [[contentRequestMock expect] setByteRangeAccessSupported:YES];
        
        sut.loadingRequest = requestMock;
        [sut fillWithResponseHeaders:headersMock];
        
        [contentRequestMock verify];
        [headersMock stopMocking];
    });
});

describe(@"fillWithData:", ^()
{
    it(@"should pass data to data request", ^()
    {
        id dataMock = OCMClassMock([NSData class]);
        [[dataRequestMock expect] respondWithData:dataMock];
        
        sut.loadingRequest = requestMock;
        [sut fillWithData:dataMock];
        
        [dataRequestMock verify];
    });
    
    it(@"should increase current location by data length", ^()
       {
           id dataMock = OCMClassMock([NSData class]);
           [[[dataMock stub] andReturnValue:OCMOCK_VALUE(20)] length];
           
           sut.loadingRequest = requestMock;
           sut.currentLocation = 15;
           [sut fillWithData:dataMock];
        
           XCTAssertEqual(sut.currentLocation, 35);
           [dataMock stopMocking];
       });
});

describe(@"finishWithError:", ^()
{
    it(@"should return immediately if already finished", ^()
    {
        [[[requestMock stub] andReturnValue:OCMOCK_VALUE(YES)] isFinished];
        
        [[requestMock reject] finishLoading];
        [[requestMock reject] finishLoadingWithError:[OCMArg any]];
        
        sut.loadingRequest = requestMock;
        [sut finishWithError:nil];
        
        [requestMock verify];
        [requestMock stopMocking];
    });
    
    it(@"should call finishLoading immediately if no error", ^()
    {
        [[[requestMock stub] andReturnValue:OCMOCK_VALUE(NO)] isFinished];
        [[requestMock expect] finishLoading];

        sut.loadingRequest = requestMock;
        [sut finishWithError:nil];
        
        [requestMock verify];
    });

    it(@"should call finishLoadingWithError if error", ^()
    {
        id errorMock = OCMClassMock([NSError class]);
        
        [[[requestMock stub] andReturnValue:OCMOCK_VALUE(NO)] isFinished];
        [[requestMock expect] finishLoadingWithError:errorMock];
        
        sut.loadingRequest = requestMock;
        [sut finishWithError:errorMock];
        
        [requestMock verify];
    });
});

describe(@"requiredOffset", ^()
{
    it(@"should return data request offset", ^()
    {
        [[[dataRequestMock stub] andReturnValue:OCMOCK_VALUE(250)] requestedOffset];
        sut.loadingRequest = requestMock;
        
        XCTAssertEqual([sut requiredOffset], 250);
    });
});

describe(@"requiredLength", ^()
{
    it(@"should return data request lenght", ^()
       {
           [[[dataRequestMock stub] andReturnValue:OCMOCK_VALUE(100)] requestedLength];
           sut.loadingRequest = requestMock;
           
           XCTAssertEqual([sut requiredLength], 100);
       });
});

describe(@"currentLocation", ^()
{
    it(@"should return current location value", ^()
    {
        sut.currentLocation = 80;
        XCTAssertEqual([sut currentLocation], 80);
    });
});

SpecEnd
