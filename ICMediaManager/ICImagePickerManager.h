//
//  ICImagePickerManager.h
//  BaseProject
//
//  Created by Fox on 13-7-11.
//  Copyright (c) 2013年 iChance. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^imagePicker_CompleteBlock)(UIImage *resultImage, UIImage *orignImage);
typedef void(^imagePicker_FailedBlock)(NSError *error);

typedef NS_ENUM(NSInteger, ICImagePickerStyleType) {
    ICImagePickerStyleTypeBoth = 0,             //通过相机和选择图片获取
    ICImagePickerStyleTypeCamera = 1,           //通过相机获取图片
    ICImagePickerStyleTypePhotoLibrary = 2      //通过相册获取图片
};

/*
 * @brief   选取照片
 * @detail  通过拍照图片、选择图片两种方式获取图片
 */
@interface ICImagePickerManager : NSObject <UIActionSheetDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate>


+ (ICImagePickerManager *)shareInstance;


- (void)imagePickerWithType:(ICImagePickerStyleType )styleType
              enableEditing:(BOOL)enableEditing
               withDelegate:(id )delegate
               comleteBlock:(imagePicker_CompleteBlock )complete_Block
                 failedBlock:(imagePicker_FailedBlock)failed_Block;

@end
