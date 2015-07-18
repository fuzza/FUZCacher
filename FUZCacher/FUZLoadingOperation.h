//
//  FUZLoadingOperation.h
//  FUZCacher
//
//  Created by fuzza on 7/18/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface FUZLoadingOperation : NSOperation

@property (nonatomic, strong) AVAssetResourceLoadingRequest *resourceLoadingRequest;

@end
