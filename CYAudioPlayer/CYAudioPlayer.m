//
//  CYAudioPlayer.m
//  HuHu
//
//  Created by CoLcY on 2018/5/22.
//  Copyright © 2018年 CoLcY. All rights reserved.
//

#import "CYAudioPlayer.h"
#import <MediaPlayer/MediaPlayer.h>

@interface CYAudioPlayer ()
{
    id mPeriodicTimeObserver;
    NSTimer *mTimingTimer;
    int mTimingCount;
    CYTimingBlock mTimingBlock;
}

@end

@implementation CYAudioPlayer
#pragma mark -
#pragma mark Init
+ (CYAudioPlayer *)sharedInstance
{
    static CYAudioPlayer *sharedInstance = nil;
    @synchronized(self) {
        if (sharedInstance == nil)
        {
            sharedInstance = [[CYAudioPlayer alloc] init];
            //initPlayer
            {
                sharedInstance.currentIndex = 0;
                sharedInstance.avPlayer = [[AVPlayer alloc] init];
                [sharedInstance remoteControlEventHandler];
            }
        }
    }
    return sharedInstance;
}

- (void)initPlayer
{
    self.currentIndex = 0;
    self.avPlayer = [[AVPlayer alloc] init];
    [self remoteControlEventHandler];
}

- (void)dealloc
{
    if (mPeriodicTimeObserver)
    {
        [self.avPlayer removeTimeObserver:mPeriodicTimeObserver];
        mPeriodicTimeObserver = nil;
    }
}

#pragma mark -
#pragma mark AVPlayer
- (void)readyWithPlayList:(NSMutableArray *)playList
{
    self.playList = playList;
    [self readyWithPlayerItem];
}

- (AVPlayerItem *)playerItemWithAudioModel:(CYAudioModel *)audioModel
{
    NSURL *url;
    if (audioModel.local)
    {
        url = [NSURL fileURLWithPath:audioModel.local];
    }
    else
    {
        url = [NSURL URLWithString:audioModel.remote];
    }
    return [[AVPlayerItem alloc] initWithURL:url];
}

- (void)handlePlayerStatus:(CYStatusBlock)statusBlock completion:(CYCompletionBlock)completionBlock
{
    mPeriodicTimeObserver = [self.avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {

        CYAudioModel *audioModel = self.playList[self.currentIndex];
        AVPlayerItem *playerItem = self.avPlayer.currentItem;
        //当前播放的时间
        float current = CMTimeGetSeconds(time);
        //总时间
        float duration = CMTimeGetSeconds(playerItem.duration);
        
        //播放进度回调
        if (statusBlock)
        {
            statusBlock(self.avPlayer, current, duration);
        }
        //播放完成的回调
        if (current >= duration)
        {
            [self playCompletion:nil];
            if (completionBlock)
            {
                completionBlock(self.avPlayer);
            }
        }
        
        //锁屏界面信息
        MPNowPlayingInfoCenter *infoCenter = [MPNowPlayingInfoCenter defaultCenter];
        MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:audioModel.artwork];
        infoCenter.nowPlayingInfo = @{
                                      MPMediaItemPropertyTitle :audioModel.title,
                                      MPMediaItemPropertyArtist :audioModel.artist,
                                      MPMediaItemPropertyPlaybackDuration :@(duration),
                                      MPNowPlayingInfoPropertyElapsedPlaybackTime : @(current),
                                      MPMediaItemPropertyArtwork : artwork
                                      };
    }];
}

- (void)play
{
    [self.avPlayer play];
}

- (void)playAtIndex:(int)index
{
    self.currentIndex = index;
    [self readyWithPlayerItem];
    [self play];
}

- (void)pause
{
    [self.avPlayer pause];
}

- (void)previous
{
    self.currentIndex --;
    if (self.currentIndex < 0)
    {
        self.currentIndex = (int)self.playList.count - 1;
    }
    [self readyWithPlayerItem];
}

- (void)next
{
    self.currentIndex ++;
    if (self.currentIndex >= (int)self.playList.count)
    {
        self.currentIndex = 0;
    }
    [self readyWithPlayerItem];
}

- (void)random
{
    self.currentIndex = rand() % self.playList.count;
    [self readyWithPlayerItem];
}

#pragma mark -
#pragma mark inner & observer
- (void)readyWithPlayerItem
{
    //移除原playerItem的完成监听--可以通过监听事件完成
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayer.currentItem];
    //状态相关
    [self.avPlayer.currentItem removeObserver:self forKeyPath:@"status" context:nil];
    [self.avPlayer.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
    
    
    CYAudioModel *audioModel = self.playList[self.currentIndex];
    AVPlayerItem *playerItem = [self playerItemWithAudioModel:audioModel];
    [self.avPlayer replaceCurrentItemWithPlayerItem:playerItem];
    
    
    //监听playerItem的完成
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playCompletion:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayer.currentItem];
    [self.avPlayer.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.avPlayer.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
//    [self.avPlayer.currentItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
//    [self.avPlayer.currentItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"])
    {
        switch (self.avPlayer.status) {
            case AVPlayerStatusUnknown:
            {
                NSLog(@"未知转态");
            }
                break;
            case AVPlayerStatusReadyToPlay:
            {
                NSLog(@"准备播放");
            }
                break;
            case AVPlayerStatusFailed:
            {
                NSLog(@"加载失败");
            }
                break;
            default:
                break;
        }
    }
    else if ([keyPath isEqualToString:@"loadedTimeRanges"])
    {
//        NSArray * timeRanges = self.avPlayer.currentItem.loadedTimeRanges;
//        //本次缓冲的时间范围
//        CMTimeRange timeRange = [timeRanges.firstObject CMTimeRangeValue];
//        //缓冲总长度
//        NSTimeInterval totalLoadTime = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration);
//        //音乐的总时间
//        NSTimeInterval duration = CMTimeGetSeconds(self.avPlayer.currentItem.duration);
//        //计算缓冲百分比例
//        NSTimeInterval scale = totalLoadTime/duration;
//        //更新缓冲进度条
//        NSLog(@"缓冲进度:%f",scale);
    }
    else if ([keyPath isEqualToString:@"playbackBufferEmpty"])
    {
        //监听播放器在缓冲数据的状态
        NSLog(@"缓冲不足暂停了");
    }
    else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"])
    {
        NSLog(@"缓冲达到可播放程度了");
        //由于 AVPlayer 缓存不足就会自动暂停，所以缓存充足了需要手动播放，才能继续播放
//        [self.avPlayer play];
    }
}

- (void)playCompletion:(id)sender
{
    switch (self.playMode)
    {
        case CYPlayModeSingleCycle:
        {
            [self readyWithPlayerItem];
            if (self.timingType == CYTimingTypeOne)
            {
                [self setIsPlaying:NO];
            }
            else
            {
                [self play];
            }
        }
            break;
        case CYPlayModeCycle:
        {
            [self next];
            if (self.timingType == CYTimingTypeOne)
            {
                [self setIsPlaying:NO];
            }
            else
            {
                [self play];
            }
        }
            break;
        case CYPlayModeRandom:
        {
            [self random];
            if (self.timingType == CYTimingTypeOne)
            {
                [self setIsPlaying:NO];
            }
            else
            {
                [self play];
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark -
#pragma mark Seek
- (void)seekBySlider:(UISlider *)sender
{
    //根据值计算时间
    float time = sender.value * CMTimeGetSeconds(self.avPlayer.currentItem.duration);
    //跳转到当前指定时间
    [self seekToTime:time];
}

- (void)seekToTime:(int)time
{
    [self.avPlayer seekToTime:CMTimeMake(time, 1)];
}

#pragma mark -
#pragma mark Timing
- (void)setOffTiming:(CYTimingType)type completion:(CYTimingBlock)block
{
    self.timingType = type;
    mTimingCount = type * 60;
    mTimingBlock = block;
    switch (self.timingType)
    {
        case CYTimingTypeNone:
        {
            [self stopTiming];
        }
            break;
        case CYTimingTypeOne:
        {
            [self stopTiming];
        }
            break;
        case CYTimingTypeFifteen:
        {
            [self startTiming];
        }
            break;
        case CYTimingTypeThirty:
        {
            [self startTiming];
        }
            break;
        case CYTimingTypeSixty:
        {
            [self startTiming];
        }
            break;
        default:
            break;
    }
}

- (void)stopTiming
{
    if (mTimingTimer)
    {
        [mTimingTimer invalidate];
        mTimingTimer = nil;
    }
}

- (void)startTiming
{
    if (!mTimingTimer)
    {
        mTimingTimer =  [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timing:) userInfo:nil repeats:YES];
    }
}

- (void)timing:(id)sender
{
    mTimingCount --;
    NSLog(@"mTimingCount:%d",mTimingCount);
    if (mTimingCount == 0)
    {
        [self pause];
        [self stopTiming];
        
        [self setIsPlaying:NO];
        if (mTimingBlock)
        {
            mTimingBlock(self.avPlayer);
        }
    }
}

#pragma mark -
#pragma mark LockScreen
- (void)remoteControlEventHandler
{
    // 直接使用sharedCommandCenter来获取MPRemoteCommandCenter的shared实例
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    // 启用播放命令 (锁屏界面和上拉快捷功能菜单处的播放按钮触发的命令)
    commandCenter.playCommand.enabled = YES;
    // 为播放命令添加响应事件, 在点击后触发
    [commandCenter.playCommand addTarget:self action:@selector(playAction:)];
    
    // 播放, 暂停, 上下曲的命令默认都是启用状态, 即enabled默认为YES
    // 为暂停, 上一曲, 下一曲分别添加对应的响应事件
    [commandCenter.pauseCommand addTarget:self action:@selector(pauseAction:)];
    [commandCenter.previousTrackCommand addTarget:self action:@selector(previousTrackAction:)];
    [commandCenter.nextTrackCommand addTarget:self action:@selector(nextTrackAction:)];
    
    // 启用耳机的播放/暂停命令 (耳机上的播放按钮触发的命令)
    commandCenter.togglePlayPauseCommand.enabled = YES;
    // 为耳机的按钮操作添加相关的响应事件
    [commandCenter.togglePlayPauseCommand addTarget:self action:@selector(playOrPauseAction:)];
}

- (void)playAction:(id)obj
{
    [self play];
}

- (void)pauseAction:(id)obj
{
    [self pause];
}

- (void)nextTrackAction:(id)obj
{
    [self next];
}

- (void)previousTrackAction:(id)obj
{
    [self previous];
}

- (void)playOrPauseAction:(id)obj
{
    if ([self isPlaying])
    {
        [self pause];
    }
    else
    {
        [self play];
    }
}

#pragma mark -
#pragma mark status
- (int)currentAudioID
{
    return [self.playList[self.currentIndex] audioID];
}
@end
