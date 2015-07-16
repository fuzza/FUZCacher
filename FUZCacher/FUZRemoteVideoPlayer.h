//
//  FUZRemoteVideoPlayer.h
//  FUZCacher
//
//  Created by fuzza on 7/16/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, FUZRemoteVideoPlayerState)
{
    FUZRemoteVideoPlayerStateUnknown = 0,
    FUZRemoteVideoPlayerStatePlaying,
    FUZRemoteVideoPlayerStateBuffering,
    FUZRemoteVideoPlayerStateStopped,
    FUZRemoteVideoPlayerStateEnded
};

@interface FUZRemoteVideoPlayer : NSObject

@property (nonatomic, strong, readonly) AVPlayerLayer *playerLayer;

- (void)setupWithVideoUrl:(NSURL *)videoUrl;
- (void)play;

@end
