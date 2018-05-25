//
//  CYAudioModel.h
//  HuHu
//
//  Created by CoLcY on 2018/5/22.
//  Copyright © 2018年 CoLcY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface CYAudioModel : NSObject
@property (nonatomic, assign) int audioID;                          //音频ID
@property (nonatomic, strong) NSString *remote;                     //远程url
@property (nonatomic, strong) NSString *local;                      //本地url
//歌曲信息
@property (nonatomic, strong) NSString *title;                      //歌曲名
@property (nonatomic, strong) NSString *artist;                     //歌手名
@property (nonatomic, assign) NSTimeInterval playbackDuration;      //歌曲时间长度
@property (nonatomic, assign) NSTimeInterval elapsedPlaybackTime;   //歌曲已播放时间长度
@property (nonatomic, strong) UIImage *artwork;                     //歌曲封面图
@end

