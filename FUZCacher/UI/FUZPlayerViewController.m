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

#pragma mark - ViewController lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString *urlString = @"http://sample-videos.com/video/mp4/360/big_buck_bunny_360p_20mb.mp4";
    
    NSURL *videoUrl = [NSURL URLWithString:urlString];
    
    [self setupRemotePlayerWithURL:videoUrl];
    [self setupSlider];
}

- (void)dealloc
{
    [self stopSliderTimer];
}

#pragma mark - Player

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

- (void)startPlayback
{
    [self.remoteVideoPlayer play];
    [self startSliderTimer];
    [self updateUI];
}

- (void)stopPlayback
{
    [self.remoteVideoPlayer pause];
    [self stopSliderTimer];
    [self updateUI];
}

#pragma mark - Slider

- (void)setupSlider
{
    self.timeSlider.continuous = NO;
    [self updateUI];
}

- (void)startSliderTimer
{
    [self stopSliderTimer];
    self.sliderTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                        target:self
                                                      selector:@selector(updateUI)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)stopSliderTimer
{
    if(self.sliderTimer)
    {
        [self.sliderTimer invalidate];
        self.sliderTimer = nil;
    }
}

#pragma mark - UI

- (void)updateUI
{
    self.timeSlider.maximumValue = [self.remoteVideoPlayer durationInSeconds] > 0 ? [self.remoteVideoPlayer durationInSeconds] : 1;
    self.timeSlider.value = [self.remoteVideoPlayer currentTimeInSeconds];
    self.playButton.selected = [self.remoteVideoPlayer isPlaying];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - IBActions

- (IBAction)startButtonDidTap:(UIButton *)sender
{
    if([self.remoteVideoPlayer isPlaying])
    {
        [self stopPlayback];
    }
    else
    {
        [self startPlayback];
    }
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
