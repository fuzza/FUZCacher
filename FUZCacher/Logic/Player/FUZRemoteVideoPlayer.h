//
//  FUZRemoteVideoPlayer.h
//  FUZCacher
//
//  Created by fuzza on 7/16/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FUZRemoteVideoPlayer : NSObject  <AVAssetResourceLoaderDelegate>

@property (nonatomic, strong, readonly) AVPlayerLayer *playerLayer;

- (void)setupWithVideoUrl:(NSURL *)videoUrl;
- (void)play;
- (void)pause;
- (void)restart;
- (void)seekToTime:(CMTime)time;
- (BOOL)isPlaying;

- (Float64)currentTimeInSeconds;
- (Float64)durationInSeconds;

@end
