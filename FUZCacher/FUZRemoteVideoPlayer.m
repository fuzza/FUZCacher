//
//  FUZRemoteVideoPlayer.m
//  FUZCacher
//
//  Created by fuzza on 7/16/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//
#import "FUZRemoteVideoPlayer.h"

@interface FUZRemoteVideoPlayer ()

@property (nonatomic, strong) AVPlayer *videoPlayer;
@property (nonatomic, strong, readwrite) AVPlayerLayer *playerLayer;
@property (nonatomic, strong, readonly) AVPlayerItem *currentItem;
@end

@implementation FUZRemoteVideoPlayer

- (void)setupWithVideoUrl:(NSURL *)videoUrl {
    self.videoPlayer = [[AVPlayer alloc] initWithURL:videoUrl];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.videoPlayer];
}

- (void)play {
    [self.videoPlayer play];
}

- (void)setVideoPlayer:(AVPlayer *)videoPlayer {
    [self resetPlayerObserving];
    _videoPlayer = videoPlayer;
    [self setupPlayerObserving];
}

- (void)dealloc {
    [self resetPlayerObserving];
}

- (void)setupPlayerObserving {
    [self.currentItem addObserver:self
                       forKeyPath:NSStringFromSelector(@selector(playbackLikelyToKeepUp))
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          context:(void *)self];
}

- (void)resetPlayerObserving {
    [self.currentItem removeObserver:self
                          forKeyPath:NSStringFromSelector(@selector(playbackLikelyToKeepUp))
                             context:(void *)self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if([keyPath isEqualToString:NSStringFromSelector(@selector(playbackLikelyToKeepUp))]) {
        [self playbackLikelyToKeepUpDidChanged];
    }
}

- (void)playbackLikelyToKeepUpDidChanged
{
    if(!self.currentItem.playbackLikelyToKeepUp &&
       CMTIME_COMPARE_INLINE(self.videoPlayer.currentTime, > ,kCMTimeZero) &&
       CMTIME_COMPARE_INLINE(self.videoPlayer.currentTime, !=, self.currentItem.duration))
    {
        [self play];
    }
}

- (AVPlayerItem *)currentItem
{
    return self.videoPlayer.currentItem;
}

@end
