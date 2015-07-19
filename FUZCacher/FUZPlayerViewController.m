//
//  FUZPlayerViewController.m
//  FUZCacher
//
//  Created by fuzza on 7/16/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import "FUZPlayerViewController.h"
#import "FUZRemoteVideoPlayer.h"

@interface FUZPlayerViewController ()

@property (nonatomic, strong) FUZRemoteVideoPlayer *remoteVideoPlayer;
@property (nonatomic, strong) UISlider *timeSlider;

@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@end

@implementation FUZPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    @"http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8";

    NSString *urlString =@"http://sample-videos.com/video/mp4/360/big_buck_bunny_360p_20mb.mp4";
    NSURL *videoUrl = [NSURL URLWithString:urlString];
    
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
    [self.view setNeedsLayout];
}

#pragma mark - IBActions

- (IBAction)resetButtonDidTap:(UIButton *)sender {
    [self.remoteVideoPlayer reload];
    [self setupPlayerView];
    [self.remoteVideoPlayer play];
}
@end
