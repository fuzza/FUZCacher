//
//  FUZPlayerView.m
//  FUZCacher
//
//  Created by fuzza on 7/19/15.
//  Copyright (c) 2015 fuzza. All rights reserved.
//

#import "FUZPlayerView.h"

@interface FUZPlayerView ()

@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@end

@implementation FUZPlayerView

- (void)setupWithPlayerLayer:(AVPlayerLayer *)playerLayer
{
    if(self.playerLayer.superlayer)
    {
        [self.playerLayer removeFromSuperlayer];
    }
    
    self.playerLayer = playerLayer;
    [self.layer addSublayer:playerLayer];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
}

@end
