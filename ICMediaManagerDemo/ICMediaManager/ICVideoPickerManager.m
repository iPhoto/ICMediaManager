//
//  ICVideoPickerManager.m
//  BaseProject
//
//  Created by Fox on 13-7-11.
//  Copyright (c) 2013年 iChance. All rights reserved.
//

#import "ICVideoPickerManager.h"


@interface ICVideoPickerManager (){
    
    ICVideoPickerStyleType _styleType;
    BOOL _isConcertMP4;     //是否转换为MP4，默认为NO
    
    UIImagePickerController *_imagePickerController;
}

@property (nonatomic, assign) ICVideoPickerStyleType styleType;
@property (nonatomic, assign) BOOL isConcertMP4;
@property (nonatomic, copy) videoPicker_CompleteBlock complete_Block;
@property (nonatomic, copy) videoPicker_FailedBlock failed_Block;

@property (nonatomic, assign) UIViewController *delegate;

@property (nonatomic, retain) UIImagePickerController *imagePickerController;

@end


@implementation ICVideoPickerManager
@synthesize styleType = _styleType;
@synthesize complete_Block = _complete_Block;
@synthesize failed_Block = _failed_Block;
@synthesize delegate = _delegate;
@synthesize imagePickerController = _imagePickerController;

#pragma mark - Memory manager
-(void)dealloc
{
    self.complete_Block = nil;
    self.failed_Block = nil;
    self.imagePickerController = nil;
}


#pragma mark - Init
+ (ICVideoPickerManager *)shareInstance{
    
    static ICVideoPickerManager *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ICVideoPickerManager alloc] init];
    });
    
    return instance;
}

-(id)init{
    self = [super init];
    if (self) {
        self.styleType = ICVideoPickerStyleTypeBoth;
        self.isConcertMP4 = NO;
        self.imagePickerController = [[UIImagePickerController alloc] init];
        self.imagePickerController.navigationController.navigationBarHidden = YES;
        
    }
    return self;
}

#pragma mark - Actions
- (void)videoPickerWithType:(ICVideoPickerStyleType )styleType
               withDelegate:(id )delegate
               isConvertMP4:(BOOL)isConcertMP4
               comleteBlock:(videoPicker_CompleteBlock )complete_Block
                 failedBlock:(videoPicker_FailedBlock)failed_Block{
    
    //判断传过来的代理是否为控制器
    if (![delegate isKindOfClass:[UIViewController class]]) {
        NSAssert(![delegate isKindOfClass:[UIViewController class]], @"传入的Delegate不是ViewController");
        return;
    }
    
    self.styleType = styleType;
    self.isConcertMP4 = isConcertMP4;
    self.delegate = delegate;
    self.complete_Block = complete_Block;
    self.failed_Block = failed_Block;
    
    
    //根据类型显示不同的试图
    if (styleType == ICVideoPickerStyleTypeBoth) {
        //显示actionsheet，供用户选择显示拍照还是选取照片
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"本地选取视频" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"拍摄视频",@"选择视频", nil];
        [actionSheet showInView:self.delegate.view];
        return;
    }
    
    if (styleType == ICVideoPickerStyleTypeCamera) {
        //通过照相机拍摄
        [self takeVideoFormCamera];
        return;
    }
    
    if (styleType == ICVideoPickerStyleTypeAlbum) {
        //通过相册选取
        [self takeVideoFormAlbum];
        return;
    }
}


- (void)takeVideoFormCamera{
    //从摄像头中获取
    
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        NSArray *temp_MediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        self.imagePickerController.mediaTypes = [NSArray arrayWithObject:temp_MediaTypes[1]];
        self.imagePickerController.delegate = self;
    }
    
    [self.delegate presentModalViewController:self.imagePickerController animated:YES];
    
}

- (void)takeVideoFormAlbum{
    //从相册中选取
    
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        NSArray *temp_MediaTypes = [UIImagePickerController availableMediaTypesForSourceType:self.imagePickerController.sourceType];
        self.imagePickerController.mediaTypes = [NSArray arrayWithObject:temp_MediaTypes[1]];
        self.imagePickerController.delegate = self;
    }
    
    [self.delegate presentModalViewController:self.imagePickerController animated:YES];
}

- (void)convertMOVtoMP4WithPath:(NSString *)orignPath{

    //将拍摄或去选取的视频转换为MP4
    NSMutableString *mp4Path = [NSMutableString stringWithString:orignPath];
    
    AVURLAsset * urlAsset = [[AVURLAsset alloc] initWithURL:[NSURL URLWithString:orignPath] options:nil];
    AVAssetExportSession * exportSession = [AVAssetExportSession exportSessionWithAsset:urlAsset presetName:AVAssetExportPreset640x480];
    //AVAssetExportPresetHighestQuality 压缩率很低
    //其他值可以查看，根据自己的需求确定
    
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    //转换为mp4文件的路径
    exportSession.outputURL = [NSURL fileURLWithPath:mp4Path];//输出的上传路径，文件不能已存在
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        switch (exportSession.status) {
            case AVAssetExportSessionStatusUnknown:
                break;
            case AVAssetExportSessionStatusWaiting:
                break;
            case AVAssetExportSessionStatusExporting:
                break;
            case AVAssetExportSessionStatusCompleted:{
                
                //将转换的mp4文件保存到本地
                if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum (mp4Path)) {
                    //将视频保存到本地
                    UISaveVideoAtPathToSavedPhotosAlbum (mp4Path, nil, nil, nil);
                }
                
                //转换完成
                self.complete_Block(mp4Path,orignPath);
                
                
            }
                break;
            case AVAssetExportSessionStatusFailed:{
                //转换失败
                NSError *error = [NSError errorWithDomain:@"转换MP4视频文件失败"
                                                     code:400
                                                 userInfo:@{@"error_msg": @"无法转换为MP4视频文件"}];
                self.failed_Block(error);
            }
                break;
            case AVAssetExportSessionStatusCancelled:{
                //转换取消
                NSError *error = [NSError errorWithDomain:@"取消转换为视频文件"
                                                     code:400
                                                 userInfo:@{@"error_msg": @"取消转换为MP4视频文件"}];
                self.failed_Block(error);
            }
                break;
            default:
                break;
        }
    }];

    
}

#pragma mark - UIActionSheetDelegate methods
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (buttonIndex == 0) {
        //拍摄照片
        [self takeVideoFormCamera];
        return;
    }
    
    if (buttonIndex == 1) {
        //选取照片
        [self takeVideoFormAlbum];
        return;
    }
    
}


#pragma mark - UINavigationControllerDelegate methods
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    
}

#pragma mark - UIImagePickerControllerDelegate methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    
    
    if ([[info objectForKey:@"UIImagePickerControllerMediaType"] isEqual:@"public.movie"]) {
        //UIImagePickerControllerReferenceURL  相册链接  UIImagePickerControllerMediaURL 本地链接地址
        
        //添加path函数，转换为实际路径，否则无法保存
        NSString *orignPath = [NSString stringWithFormat:@"%@",[[info objectForKey:UIImagePickerControllerMediaURL] path]];
        
        //拍摄的照片才保存在本地，选取的照片不用保存
        if (picker.sourceType == UIImagePickerControllerSourceTypeCamera &&
            UIVideoAtPathIsCompatibleWithSavedPhotosAlbum (orignPath)) {
            //将视频保存到本地
                UISaveVideoAtPathToSavedPhotosAlbum (orignPath, nil, nil, nil);
        }
        
        if (self.isConcertMP4 == YES) {
            //需要转换为MP4文件
            [self convertMOVtoMP4WithPath:orignPath];
        }else{
            //不需要转换
            self.complete_Block(orignPath,orignPath);
        }
    }else{
        //读取失败
        NSError *error = [NSError errorWithDomain:@"视频获取失败" code:400 userInfo:@{@"error_msg": @"无法获取视频"}];
        self.failed_Block(error);
    }
    
    [picker dismissModalViewControllerAnimated:YES];
    
    self.complete_Block = nil;
    self.failed_Block = nil;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissModalViewControllerAnimated:YES];
}




@end
