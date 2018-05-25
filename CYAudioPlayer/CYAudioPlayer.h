//
//  CYAudioPlayer.h
//  HuHu
//
//  Created by CoLcY on 2018/5/22.
//  Copyright © 2018年 CoLcY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "CYAudioModel.h"

#define CYSharedAudioPlayer [CYAudioPlayer sharedInstance]

typedef enum CYPlayMode
{
    CYPlayModeNone = 0,
    CYPlayModeCycle = 1,            //循环
    CYPlayModeSingleCycle = 2,      //单曲循环
    CYPlayModeRandom = 3            //随机播放
}CYPlayMode;

typedef enum CYTimingType
{
    CYTimingTypeNone = 0,
    CYTimingTypeOne = 1,
    CYTimingTypeFifteen = 15,
    CYTimingTypeThirty = 30,
    CYTimingTypeSixty = 60
}CYTimingType;

typedef void (^CYStatusBlock)(AVPlayer *avPlayer, int current, int total);
typedef void (^CYCompletionBlock)(AVPlayer *avPlayer);
typedef void (^CYTimingBlock)(AVPlayer *avPlayer);

@interface CYAudioPlayer : NSObject
@property (nonatomic, assign) BOOL isPlaying;               //外部控制+内部控制，比如：拖动进度条的时候，需要暂停
@property (nonatomic, assign) int currentIndex;
@property (nonatomic, strong) NSMutableArray<CYAudioModel *> *playList;
@property (nonatomic, strong) AVPlayer *avPlayer;
@property (nonatomic, assign) CYPlayMode playMode;
@property (nonatomic, assign) CYTimingType timingType;
@property (nonatomic, strong) UIViewController *currentController;
+ (CYAudioPlayer *)sharedInstance;

/**
 * 初始化需要播放的音频列表，并准备currentIndex指定的音频
 */
- (void)readyWithPlayList:(NSMutableArray *)playList;

/**
 * 事件监听，statusBlock用于播放进度，completionBlock用于播放完成
 */
- (void)handlePlayerStatus:(CYStatusBlock)statusBlock completion:(CYCompletionBlock)completionBlock;

//基础播放操作
- (void)play;
- (void)playAtIndex:(int)index;
- (void)pause;
- (void)previous;
- (void)next;
- (void)random;
//拖动播放
- (void)seekBySlider:(UISlider *)slder;
- (void)seekToTime:(int)time;
//定时
- (void)setOffTiming:(CYTimingType)type completion:(CYTimingBlock)block;
//状态相关
- (int)currentAudioID;
@end
