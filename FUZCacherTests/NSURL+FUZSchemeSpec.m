//
//  NSURL+FUZSchemeSpec.m
//  FUZCacher
//
//  Created by fuzza on 7/18/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import <Specta/Specta.h>
#import <Expecta/Expecta.h>

#import "NSURL+FUZScheme.h"

SpecBegin(NSURL)

describe(@"fuz_urlWithScheme:", ^()
{
    it(@"should return new url with provided scheme", ^()
    {
        NSURL *originalUrl = [NSURL URLWithString:@"http://sometesturl.com"];
        NSURL *customSchemeUrl = [originalUrl fuz_urlWithScheme:@"custom"];
        EXP_expect([customSchemeUrl absoluteString]).equal(@"custom://sometesturl.com");
    });
});

SpecEnd