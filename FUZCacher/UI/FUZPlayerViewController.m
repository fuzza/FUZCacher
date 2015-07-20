//
//  FUZPlayerViewController.m
//  FUZCacher
//
//  Created by fuzza on 7/16/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import "FUZPlayerViewController.h"
#import "FUZRemoteVideoPlayer.h"
#import "FUZPlayerView.h"

@interface FUZPlayerViewController ()

@property (nonatomic, weak) IBOutlet UISlider *timeSlider;
@property (nonatomic, weak) IBOutlet FUZPlayerView *playerView;
@property (nonatomic, weak) IBOutlet UIButton *playButton;

@property (nonatomic, strong) FUZRemoteVideoPlayer *remoteVideoPlayer;
@property (nonatomic, strong) NSTimer *sliderTimer;

@end

@implementation FUZPlayerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString *urlString = @"http://sample-videos.com/video/mp4/360/big_buck_bunny_360p_20mb.mp4";
    
    NSURL *videoUrl = [NSURL URLWithString:urlString];
    
    [self setupRemotePlayerWithURL:videoUrl];
    [self setupSlider];
}

- (void)setupRemotePlayerWithURL:(NSURL *)videoUrl
{
    self.remoteVideoPlayer = [[FUZRemoteVideoPlayer alloc] init];
    [self.remoteVideoPlayer setupWithVideoUrl:videoUrl];
    [self setupPlayerView];
}

- (void)setupPlayerView
{
    [self.playerView setupWithPlayerLayer:self.remoteVideoPlayer.playerLayer];
    [self.playerView setNeedsLayout];
}

#pragma mark - Slider

- (void)setupSlider
{
    self.sliderTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                         target:self
                                                       selector:@selector(updateUI)
                                                       userInfo:nil
                                                        repeats:YES];
    [self updateUI];
    self.timeSlider.continuous = NO;
}

- (void)updateUI
{
    self.timeSlider.maximumValue = [self.remoteVideoPlayer durationInSeconds] > 0 ? [self.remoteVideoPlayer durationInSeconds] : 1;
    self.timeSlider.value = [self.remoteVideoPlayer currentTimeInSeconds];
    self.playButton.selected = [self.remoteVideoPlayer isPlaying];
}

#pragma mark - IBActions

- (IBAction)startButtonDidTap:(UIButton *)sender
{
    if([self.remoteVideoPlayer isPlaying])
    {
        [self.remoteVideoPlayer pause];
    }
    else
    {
        [self.remoteVideoPlayer play];
    }
    [self updateUI];
}

- (IBAction)resetButtonDidTap:(UIButton *)sender
{
    [self.remoteVideoPlayer restart];
    [self setupPlayerView];
    [self.remoteVideoPlayer play];
}

- (IBAction)timeSliderDidChange:(UISlider *)sender
{
    CMTime newTime = CMTimeMakeWithSeconds(sender.value, 1);
    [self.remoteVideoPlayer seekToTime:newTime];
}

@end
