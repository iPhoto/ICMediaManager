//
//  ICVideoPickerManager.h
//  BaseProject
//
//  Created by Fox on 13-7-11.
//  Copyright (c) 2013年 iChance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

//成功和失败的回调，成功时返回视频的目标文件的路径和源文件的路径
typedef void(^videoPicker_CompleteBlock)(NSString *resultPath, NSString *orignPath);
typedef void(^videoPicker_FailedBlock)(NSError *error);

typedef NS_ENUM(NSInteger, ICVideoPickerStyleType) {
    ICVideoPickerStyleTypeBoth = 0,             //通过相机和选择视频获取
    ICVideoPickerStyleTypeCamera = 1,           //通过相机获取视频
    ICVideoPickerStyleTypeAlbum = 2             //通过系统专辑获取视频
};

/*
 * @brief   选取视频
 * @detail  通过拍照视频、选择视频两种方式获取视频
 */
@interface ICVideoPickerManager : NSObject <UIActionSheetDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate>

+ (ICVideoPickerManager *)shareInstance;


- (void)videoPickerWithType:(ICVideoPickerStyleType )styleType
               withDelegate:(id )delegate
               isConvertMP4:(BOOL)isConcertMP4
               comleteBlock:(videoPicker_CompleteBlock )complete_Block
                 failedBlock:(videoPicker_FailedBlock)failed_Block;

@end
