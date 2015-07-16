//
//  FUZPlayerViewController.m
//  FUZCacher
//
//  Created by fuzza on 7/16/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import "FUZPlayerViewController.h"
#import "FUZRemoteVideoPlayer.h"
#import "FUZCachedURLProtocol.h"

@interface FUZPlayerViewController ()

@property (nonatomic, strong) FUZRemoteVideoPlayer *remoteVideoPlayer;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@end

@implementation FUZPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *urlString = @"http://sample-videos.com/video/mp4/720/big_buck_bunny_720p_50mb.mp4";
    NSURL *videoUrl = [NSURL URLWithString:urlString];
    
    [NSURLProtocol registerClass:[FUZCachedURLProtocol class]];
    
    [self setupRemotePlayerWithURL:videoUrl];
    [self.remoteVideoPlayer play];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.playerLayer.frame = self.view.bounds;
}

- (void)setupRemotePlayerWithURL:(NSURL *)videoUrl {
    self.remoteVideoPlayer = [[FUZRemoteVideoPlayer alloc] init];
    [self.remoteVideoPlayer setupWithVideoUrl:videoUrl];
    
    [self setupPlayerView];
}

- (void)setupPlayerView {
    self.playerLayer = self.remoteVideoPlayer.playerLayer;
    [self.view.layer addSublayer:self.playerLayer];
}

@end
