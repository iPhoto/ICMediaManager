//
//  ICImagePickerManager.m
//  BaseProject
//
//  Created by Fox on 13-7-11.
//  Copyright (c) 2013年 iChance. All rights reserved.
//

#import "ICImagePickerManager.h"
#import "AppSession.h"

BOOL isPad() {
#ifdef UI_USER_INTERFACE_IDIOM
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#else
    return NO;
#endif
}

@interface ICImagePickerManager (){
    
    ICImagePickerStyleType _styleType;
    BOOL _enableEditing;
    
    UIImagePickerController *_imagePickerController;
}

@property (nonatomic, assign) ICImagePickerStyleType styleType;
@property (nonatomic, assign) BOOL enableEditing;
@property (nonatomic, copy) imagePicker_CompleteBlock complete_Block;
@property (nonatomic, copy) imagePicker_FailedBlock failed_Block;

@property (nonatomic, assign) UIViewController *delegate;

@property (nonatomic, retain) UIImagePickerController *imagePickerController;
@property (nonatomic, retain) UIPopoverController *popoverVC;

@end


@implementation ICImagePickerManager
@synthesize styleType = _styleType;
@synthesize enableEditing = _enableEditing;
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
    self.popoverVC = nil;
}


#pragma mark - Init
+ (ICImagePickerManager *)shareInstance{
    
    static ICImagePickerManager *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ICImagePickerManager alloc] init];
    });
    
    return instance;
}

-(id)init{
    self = [super init];
    if (self) {
        self.styleType = ICImagePickerStyleTypeBoth;
        self.enableEditing = NO;
        self.imagePickerController = [[UIImagePickerController alloc] init];
        self.imagePickerController.navigationController.navigationBarHidden = YES;
        
    }
    return self;
}

#pragma mark - Actions
- (void)imagePickerWithType:(ICImagePickerStyleType )styleType
              enableEditing:(BOOL)enableEditing
               withDelegate:(id )delegate
               comleteBlock:(imagePicker_CompleteBlock )complete_Block
                failedBlock:(imagePicker_FailedBlock)failed_Block{
    
    //判断传过来的代理是否为控制器
    if (![delegate isKindOfClass:[UIViewController class]]) {
        NSAssert(![delegate isKindOfClass:[UIViewController class]], @"传入的Delegate不是ViewController");
        return;
    }
    
    self.styleType = styleType;
    self.enableEditing = enableEditing;
    self.delegate = delegate;
    self.complete_Block = complete_Block;
    self.failed_Block = failed_Block;
    
    
    //根据类型显示不同的试图
    if (styleType == ICImagePickerStyleTypeBoth) {
        //显示actionsheet，供用户选择显示拍照还是选取照片
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                                 delegate:self
                                                        cancelButtonTitle:@"取消"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"拍照选取",@"从相册中选取", nil];
        [actionSheet showInView:self.delegate.view];
        return;
    }
    
    if (styleType == ICImagePickerStyleTypeCamera) {
        //通过照相机拍摄
        [self takePhotoFormCamer];
        return;
    }
    
    if (styleType == ICImagePickerStyleTypePhotoLibrary) {
        //通过相册选取
        [self takePhotoFormPhotoLibrary];
        return;
    }
}


- (void)takePhotoFormCamer{
    //从摄像头中获取
    
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        NSArray *temp_MediaTypes = [UIImagePickerController availableMediaTypesForSourceType:self.imagePickerController.sourceType];
        self.imagePickerController.mediaTypes = [NSArray arrayWithObject:temp_MediaTypes[0]];;
        self.imagePickerController.delegate = self;
        [self.imagePickerController setAllowsEditing:self.enableEditing];
        
    }
    
    [self.delegate presentModalViewController:self.imagePickerController animated:YES];
    
}

- (void)takePhotoFormPhotoLibrary{
    //从相册中选取
    
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        NSArray *temp_MediaTypes = [UIImagePickerController availableMediaTypesForSourceType:self.imagePickerController.sourceType];
        self.imagePickerController.mediaTypes = temp_MediaTypes;
        self.imagePickerController.delegate = self;
        [self.imagePickerController setAllowsEditing:self.enableEditing];
    }
    
    //从相册中选取在iPhone上和iPad上是有区别的，iPhone上可以直接presentModalViewController，但是在iPad上需要使用UIPopoverController进行弹出
    if (isPad() == NO) {
        [self.delegate presentModalViewController:self.imagePickerController animated:YES];
    }else{
        //在iPad上处理
        UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:self.imagePickerController];
        self.popoverVC = popover;
        [popover presentPopoverFromRect:CGRectMake(0, 0, 768, 300)
                                 inView:self.delegate.view
               permittedArrowDirections:UIPopoverArrowDirectionAny
                               animated:YES];
        
    }
    
    
}



#pragma mark - UIActionSheetDelegate methods
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (buttonIndex == 0) {
        //拍摄照片
        [self takePhotoFormCamer];
        return;
    }
    
    if (buttonIndex == 1) {
        //选取照片
        [self takePhotoFormPhotoLibrary];
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
    
    [picker dismissModalViewControllerAnimated:YES];
    
    
    if (self.popoverVC != nil) {
        [self.popoverVC dismissPopoverAnimated:YES];
        self.popoverVC = nil;
    }
    
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera ||
        picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary ||
        picker.sourceType == UIImagePickerControllerSourceTypeSavedPhotosAlbum) {
        //如果是从照相机中拍摄的图片
        
        //获取原始图片
        UIImage *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        //        //图片保存本地
        //        UIImageWriteToSavedPhotosAlbum(originalImage,self,@selector(image:didFinishSavingWithError:contextInfo:),nil);
        
        
        // 原始图片可以根据照相时的角度来显示，但UIImage无法判定，于是出现获取的图片会向左转９０度的现象。
        // 以下为调整图片角度的部分
        UIGraphicsBeginImageContext(originalImage.size);
        [originalImage drawInRect:CGRectMake(0, 0, originalImage.size.width, originalImage.size.height)];
        originalImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        // 调整图片角度完毕
        
        
        if (self.enableEditing == YES) {
            // 获取选择框内的图片
            CGRect cropRect = [[info objectForKey:UIImagePickerControllerCropRect] CGRectValue];
            CGImageRef imageRef = CGImageCreateWithImageInRect(originalImage.CGImage, cropRect);
            UIImage *imageCropped =[UIImage imageWithCGImage:imageRef];
            CGImageRelease(imageRef);
            
            self.complete_Block([self scaleToSize:CGSizeMake(100, 100) UIImage:imageCropped],originalImage);
        }else{
            //直接输入原图
            self.complete_Block(originalImage,originalImage);
        }
    }else{
        //读取图片错误
        NSError *error = [NSError errorWithDomain:@"读取照片错误" code:400 userInfo:@{@"error_msg": @"无法获取图片"}];
        self.failed_Block(error);
    }
    
    self.complete_Block = nil;
    self.failed_Block = nil;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if (self.popoverVC != nil) {
        [self.popoverVC dismissPopoverAnimated:YES];
        self.popoverVC = nil;
    }
    
    [picker dismissModalViewControllerAnimated:YES];
    
    self.complete_Block = nil;
    self.failed_Block = nil;
}


- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    //图片保存本地
}


#pragma mark - Tools
//等比例缩放
-(UIImage*)scaleToSize:(CGSize)size UIImage:(UIImage *)image
{
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    
    float verticalRadio = size.height*1.0/height;
    float horizontalRadio = size.width*1.0/width;
    
    float radio = 1;
    if(verticalRadio >= 1 && horizontalRadio >= 1)
    {
        radio = verticalRadio < horizontalRadio ? verticalRadio : horizontalRadio;
    }
    else
    {
        radio = verticalRadio < horizontalRadio ? verticalRadio : horizontalRadio;
    }
    
    width = width*radio;
    height = height*radio;
    
    int xPos = (size.width - width)/2;
    int yPos = (size.height-height)/2;
    
    // 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    
    // 绘制改变大小的图片
    [image drawInRect:CGRectMake(xPos, yPos, width, height)];
    
    // 从当前context中创建一个改变大小后的图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    
    // 返回新的改变大小后的图片
    return scaledImage;
}



@end
