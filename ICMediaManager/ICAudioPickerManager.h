//
//  ICAudioPickerManager.h
//  BaseProject
//
//  Created by Fox on 13-7-11.
//  Copyright (c) 2013年 iChance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "ICTools.h"

//成功和失败的回调，成功时返回音频的目标文件的路径和源文件的路径
typedef void(^audioPicker_CompleteBlock)(NSString *resultPath, NSString *orignPath);
typedef void(^audioPicker_FailedBlock)(NSError *error);

typedef NS_ENUM(NSInteger, ICAudioPickerStyleType) {
    ICAudioPickerStyleTypeBoth = 0,             //通过录音和选择音频获取
    ICAudioPickerStyleTypeRecord = 1,           //通过录音获取音频
    ICAudioPickerStyleTypeAlbum = 2             //通过系统专辑获取音频
};


/*
 * @brief   选取音频
 * @detail  通过录制音频、选择音频两种方式获取音频
 */
@interface ICAudioPickerManager : NSObject <UIActionSheetDelegate,MPMediaPickerControllerDelegate>

+ (ICAudioPickerManager *)shareInstance;


- (void)audioPickerWithType:(ICAudioPickerStyleType )styleType
               withDelegate:(id )delegate
               isConvertMP3:(BOOL)isConcertMP3
               comleteBlock:(audioPicker_CompleteBlock )complete_Block
                 failedBloc:(audioPicker_FailedBlock)failed_Block;


@end
