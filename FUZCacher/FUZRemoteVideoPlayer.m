//
//  FUZRemoteVideoPlayer.m
//  FUZCacher
//
//  Created by fuzza on 7/16/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//
#import "FUZRemoteVideoPlayer.h"
#import "FUZLoadingOperation.h"

@interface FUZRemoteVideoPlayer () <AVAssetResourceLoaderDelegate>

@property (nonatomic, strong) NSOperationQueue *operationQueue;

@property (nonatomic, strong) AVPlayer *videoPlayer;
@property (nonatomic, strong, readwrite) AVPlayerLayer *playerLayer;
@property (nonatomic, strong, readonly) AVPlayerItem *currentItem;
@property (nonatomic, strong) NSURL *currentURL;

@property (nonatomic, strong) FUZLoadingOperation *currentOperation;

@end

@implementation FUZRemoteVideoPlayer

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        self.operationQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void)setupWithVideoUrl:(NSURL *)videoUrl {
    self.currentURL = videoUrl;
    
//    [NSURLProtocol registerClass:[FUZCachedURLProtocol class]];
    
//    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[self videoURLWithCustomScheme:@"streaming"] options:nil];
    [asset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];

    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    self.videoPlayer = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.videoPlayer];
    
    [self.videoPlayer play];
}

- (NSURL *)videoURLWithCustomScheme:(NSString *)scheme {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[self currentURL] resolvingAgainstBaseURL:NO];
    components.scheme = scheme;
    return [components URL];
}

- (void)play {
    [self.videoPlayer play];
}

- (void)reload {
    [self.videoPlayer pause];
    self.videoPlayer = nil;
    
    if(self.playerLayer.superlayer)
    {
        [self.playerLayer removeFromSuperlayer];
        self.playerLayer = nil;
    }

    [self setupWithVideoUrl:self.currentURL];
    
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

#pragma mark - AVAssetResourceLoaderDelegate

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    self.currentOperation = [FUZLoadingOperation new];
    self.currentOperation.resourceLoadingRequest = loadingRequest;
    [self.operationQueue addOperation:self.currentOperation];
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [self.currentOperation cancel];
}

@end
