//
//  FUZRemoteVideoPlayer.m
//  FUZCacher
//
//  Created by fuzza on 7/16/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//
#import "FUZRemoteVideoPlayer.h"
#import "FUZLoadingOperation.h"
#import "NSURL+FUZScheme.h"
#import "FUZMP4LoaderDelegate.h"
#import "FUZCache.h"

NSString * const kPlaybackLikelyToKeepUpKey = @"playbackLikelyToKeepUp";

@interface FUZRemoteVideoPlayer () <AVAssetResourceLoaderDelegate>

@property (nonatomic, strong) FUZCache *playerCache;
@property (nonatomic, strong) AVPlayer *videoPlayer;
@property (nonatomic, strong, readwrite) AVPlayerLayer *playerLayer;
@property (nonatomic, strong, readonly) AVPlayerItem *currentItem;
@property (nonatomic, assign, readwrite, getter=isPlaying) BOOL playing;

@property (nonatomic, strong) NSURL *currentURL;
@property (nonatomic, strong) FUZMP4LoaderDelegate *loader;

@end

@implementation FUZRemoteVideoPlayer

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        self.playerCache = [[FUZCache alloc] init];
    }
    return self;
}

- (void)setupWithVideoUrl:(NSURL *)videoUrl
{
    self.currentURL = videoUrl;
    
    AVURLAsset *asset = nil;
    if([videoUrl.pathExtension isEqualToString:@"mp4"])
    {
        asset = [AVURLAsset URLAssetWithURL:[videoUrl fuz_urlWithScheme:@"streaming"] options:nil];
        
        FUZCacheEntity *cache = [self.playerCache cacheEntityForURL:self.currentURL];
        
        self.loader = [[FUZMP4LoaderDelegate alloc] init];
        [self.loader setupWithCache:cache];
        [asset.resourceLoader setDelegate:self.loader queue:dispatch_get_main_queue()];
    }
    else
    {
        asset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
    }

    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    self.videoPlayer = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.videoPlayer];
}

- (void)play
{
    [self.videoPlayer play];
    self.playing = YES;
}

- (void)pause
{
    [self.videoPlayer pause];
    self.playing = NO;
}

- (void)restart
{
    [self.loader cancelLoading];
    [self.videoPlayer pause];
    self.videoPlayer = nil;
    
    if(self.playerLayer.superlayer)
    {
        [self.playerLayer removeFromSuperlayer];
        self.playerLayer = nil;
    }

    [self setupWithVideoUrl:self.currentURL];
}

- (void)setVideoPlayer:(AVPlayer *)videoPlayer
{
    [self resetPlayerObserving];
    _videoPlayer = videoPlayer;
    [self setupPlayerObserving];
}

- (void)dealloc
{
    [self resetPlayerObserving];
}

- (void)setupPlayerObserving
{
    [self.currentItem addObserver:self
                       forKeyPath:kPlaybackLikelyToKeepUpKey
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          context:(void *)self];
}

- (void)resetPlayerObserving
{
    [self.currentItem removeObserver:self
                          forKeyPath:kPlaybackLikelyToKeepUpKey
                             context:(void *)self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if([keyPath isEqualToString:kPlaybackLikelyToKeepUpKey])
    {
        [self playbackLikelyToKeepUpDidChanged];
    }
}

- (void)playbackLikelyToKeepUpDidChanged
{
    if(!self.currentItem.playbackLikelyToKeepUp &&
       CMTIME_COMPARE_INLINE(self.videoPlayer.currentTime, > ,kCMTimeZero) &&
       CMTIME_COMPARE_INLINE(self.videoPlayer.currentTime, !=, self.currentItem.duration) &&
       self.isPlaying)
    {
        [self play];
    }
}

- (AVPlayerItem *)currentItem
{
    return self.videoPlayer.currentItem;
}

- (void)seekToTime:(CMTime)time
{
    [self.videoPlayer seekToTime:time];
}

- (Float64)currentTimeInSeconds
{
    Float64 time = CMTimeGetSeconds([self.videoPlayer currentTime]);
    return time;
}

- (Float64)durationInSeconds
{
    Float64 dur = CMTimeGetSeconds(self.currentItem.duration);
    return dur;
}

@end
