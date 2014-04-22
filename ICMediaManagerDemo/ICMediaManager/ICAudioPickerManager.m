//
//  ICAudioPickerManager.m
//  BaseProject
//
//  Created by Fox on 13-7-11.
//  Copyright (c) 2013年 iChance. All rights reserved.
//

#import "ICAudioPickerManager.h"

@interface ICAudioPickerManager () <AVAudioPlayerDelegate>{
    
    ICAudioPickerStyleType _styleType;
    BOOL _isConcertMP3;     //是否转换为MP4，默认为NO
    
    NSURL *recordedFile;                        //存放路径
    
    MPMediaPickerController *_mediaPicker;       //选取音频文件控制器
    AVAudioRecorder *_audioRecoder;              //录音对象
    AVAudioPlayer *player;                       //播放录音
    
    //录音界面
    UIView *_backView;                  //总体背景
    UIImageView *_navigationBar;        //导航背景
    UIButton *_cancelBtn;                //取消按钮
    UIButton *_submitBtn;                //提交按钮
    UIButton *_recordBtn;                //录制按钮
    UIButton *playBtn;                  //播放按钮
    
    UILabel *_timeLabel;                 //录制时间
    long  _timeValue;                //录制时间
    NSTimer *_repeatTime;                //计时器
    BOOL _isRecord;                      //是否在录制中，默认为NO
    
}

@property (nonatomic, assign) ICAudioPickerStyleType styleType;
@property (nonatomic, assign) BOOL isConcertMP3;
@property (nonatomic, copy) audioPicker_CompleteBlock complete_Block;
@property (nonatomic, copy) audioPicker_FailedBlock failed_Block;
@property (nonatomic, assign) UIViewController *delegate;

@property (nonatomic, retain) MPMediaPickerController *mediaPicker;
@property (nonatomic, retain) AVAudioRecorder *audioRecoder;

@end


@implementation ICAudioPickerManager
@synthesize styleType = _styleType;
@synthesize complete_Block = _complete_Block;
@synthesize failed_Block = _failed_Block;
@synthesize delegate = _delegate;
@synthesize mediaPicker = _mediaPicker;
@synthesize audioRecoder = _audioRecoder;

#pragma mark - Memory mananger
-(void)dealloc{
    self.complete_Block = nil;
    self.failed_Block = nil;
    self.mediaPicker = nil;
    self.audioRecoder = nil;
}

#pragma mark - Init
+ (ICAudioPickerManager *)shareInstance{
    
    static ICAudioPickerManager *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ICAudioPickerManager alloc] init];
    });
    
    return instance;
}

-(id)init{
    self = [super init];
    if (self) {
        self.styleType = ICAudioPickerStyleTypeBoth;
        self.isConcertMP3 = NO;
        
        _isRecord = NO;
        
        //初始化选取音频控制器
        self.mediaPicker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
        self.mediaPicker.delegate = self;
        self.mediaPicker.prompt = @"请选择音频文件";//提示文字
        self.mediaPicker.allowsPickingMultipleItems = NO;  //是否允许一次选择多个
        
        //初始化录制音频控制器
        
        //===========================================================================//
        //录音的设置参数，通过字典进行设置，有如下四种一般的键：
        /*
         1、一般的音频设置
         2、线性PCM设置
         3、编码器设置
         4、采样率转换设置
         */
        
        NSMutableDictionary *recordSettings = [NSMutableDictionary dictionaryWithCapacity:0];
        
        //1、一般的音频设置（ID号）
        [recordSettings setObject: [NSNumber numberWithInt: kAudioFormatLinearPCM] forKey: AVFormatIDKey];
    
        //2 采样率
        float sampleRate = 12.5;
        [recordSettings setObject: [NSNumber numberWithFloat:sampleRate] forKey: AVSampleRateKey];
        
        //3 通道的数目
        [recordSettings setObject:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
        
        //4 采样位数  默认 16
        int bitDepth = 16;
        [recordSettings setObject:[NSNumber numberWithInt:bitDepth] forKey:AVLinearPCMBitDepthKey];
        
        //5 
        [recordSettings setObject:[NSNumber numberWithBool:YES]forKey:AVLinearPCMIsBigEndianKey];
        
        //6 采样信号是整数还是浮点数  
        [recordSettings setObject:[NSNumber numberWithBool:YES]forKey:AVLinearPCMIsFloatKey];
        
        //===========================参数配置完毕===============================================//
       
        NSError *error = nil;
        AVAudioSession *session = [AVAudioSession sharedInstance];//得到AVAudioSession单例对象
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error: &error];//设置类别,表示该应用同时支持播放和录音
        [session setActive:YES error: &error];//启动音频会话管理,此时会阻断后台音乐的播放.
        
        
        NSString *destinationString = [[self documentsPath] stringByAppendingPathComponent:@"recordfile"];
        recordedFile = [[NSURL alloc] initFileURLWithPath:destinationString];
        
    }
    return self;
}

#pragma mark - Actions
- (void)audioPickerWithType:(ICAudioPickerStyleType )styleType
               withDelegate:(id )delegate
               isConvertMP3:(BOOL)isConcertMP3
               comleteBlock:(audioPicker_CompleteBlock )complete_Block
                 failedBloc:(audioPicker_FailedBlock)failed_Block{
    
    //判断传过来的代理是否为控制器
    if (![delegate isKindOfClass:[UIViewController class]]) {
        NSAssert(![delegate isKindOfClass:[UIViewController class]], @"传入的Delegate不是ViewController");
        return;
    }
    
    self.styleType = styleType;
    self.isConcertMP3 = isConcertMP3;
    self.delegate = delegate;
    self.complete_Block = complete_Block;
    self.failed_Block = failed_Block;
    
    
    //根据类型显示不同的试图
    if (styleType == ICAudioPickerStyleTypeBoth) {
        //显示actionsheet，供用户选择显示拍照还是选取照片
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"本地选取音频" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"录制音频",@"选择音频", nil];
        [actionSheet showInView:self.delegate.view];
        return;
    }
    
    if (styleType == ICAudioPickerStyleTypeRecord) {
        //录制声音
        [self takeAudioFormRecord];
        return;
    }
    
    if (styleType == ICAudioPickerStyleTypeAlbum) {
        //通过相册选取音频
        [self takeAudioFormAlbum];
        return;
    }
    
}


- (void)takeAudioFormRecord{
    //从录音中获取
    [self showRecordViews];
}

- (void)takeAudioFormAlbum{
    //从相册中选取
    [self.delegate presentViewController:self.mediaPicker animated:YES completion:^{
        //选取完成后
    } ];
}

- (void)showRecordViews{
    //初始化录制界面
    
    //总体背景
    _backView = [[UIView alloc] initWithFrame:self.delegate.view.bounds];
    _backView.backgroundColor = [UIColor darkGrayColor];
    [self.delegate.view addSubview:_backView];
    
    //导航背景
    float MainView_Height = _backView.frame.size.height;
    float MainView_Width = _backView.frame.size.width;
    _navigationBar = [[UIImageView alloc] initWithFrame:CGRectMake(0, MainView_Height - 54, 320, 54)];
    _navigationBar.image = [UIImage imageNamed:@"audioManager_audioBack.png"];
    [self.delegate.view addSubview:_navigationBar];
    
    //取消按钮
    _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_cancelBtn setFrame:CGRectMake(0, MainView_Height - 54, 100, 54)];
    [_cancelBtn setImage:[UIImage imageNamed:@"audioManager_closeBtn.png"] forState:UIControlStateNormal];
    [_cancelBtn setImage:[UIImage imageNamed:@"audioManager_closeBtnPress.png"] forState:UIControlStateSelected];
    [_cancelBtn setImage:[UIImage imageNamed:@"audioManager_closeBtnPress.png"] forState:UIControlStateHighlighted];
    [_cancelBtn addTarget:self action:@selector(cancelCurrentView:) forControlEvents:UIControlEventTouchUpInside];
    [self.delegate.view addSubview:_cancelBtn];
    
    //提交按钮
    _submitBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_submitBtn setFrame:CGRectMake(MainView_Width - 100, MainView_Height - 54, 100, 54)];
    [_submitBtn setImage:[UIImage imageNamed:@"audioManager_finishBtn.png"] forState:UIControlStateNormal];
    [_submitBtn setImage:[UIImage imageNamed:@"audioManager_finishBtnPress.png"] forState:UIControlStateSelected];
    [_submitBtn setImage:[UIImage imageNamed:@"audioManager_finishBtnPress.png"] forState:UIControlStateHighlighted];
    [_submitBtn addTarget:self action:@selector(recordFinished:) forControlEvents:UIControlEventTouchUpInside];
    [self.delegate.view addSubview:_submitBtn];
    
    //录制按钮
    _recordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_recordBtn setFrame:CGRectMake((MainView_Width - 120)/2, MainView_Height - 54, 120, 54)];
    [_recordBtn setImage:[UIImage imageNamed:@"audioManager_recordBtn"] forState:UIControlStateNormal];
    [_recordBtn setImage:[UIImage imageNamed:@"audioManager_recordBtn"] forState:UIControlStateSelected];
    [_recordBtn setImage:[UIImage imageNamed:@"audioManager_recordBtn"] forState:UIControlStateHighlighted];
    [_recordBtn addTarget:self action:@selector(recordBtnPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.delegate.view addSubview:_recordBtn];;
    
    //录制时间
    _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, MainView_Width - 20, 20)];
    _timeLabel.backgroundColor = [UIColor clearColor];
    _timeLabel.textAlignment = NSTextAlignmentRight;
    _timeLabel.text = @"00:00:00";
    [self.delegate.view addSubview:_timeLabel];
    
    
    //播放按钮
    playBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [playBtn setTitle:@"play" forState:UIControlStateNormal];
    [playBtn setFrame:CGRectMake(100, 100, 100, 40)];
    [playBtn addTarget:self action:@selector(playAudioAction:)
      forControlEvents:UIControlEventTouchUpInside];
    [self.delegate.view addSubview:playBtn];

}


- (void)convertMOVtoMP3WithPath:(NSString *)orignPath{
    
}

- (NSString*) documentsPath {
    //获取document目录的路径
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [NSString stringWithFormat:@"%@",[searchPaths objectAtIndex:0]];
}

#pragma mark - Audio Record actions
-(void)startUpdateTime {
    
    //开始更新时间
    _timeValue = 0;
    _timeLabel.text = @"00:00:00";
    _repeatTime = [NSTimer scheduledTimerWithTimeInterval:1
                                                   target:self
                                                 selector:@selector(updateTime)
                                                 userInfo:nil repeats:YES];
}

-(void)stopUpdateTime {
    //停止更新时间
    if ([_repeatTime isValid]) {
        [_repeatTime invalidate];
        _repeatTime = nil;
    }
    
}

- (void)updateTime{
    //更新时间
    _isRecord = YES;
    _timeValue++;
    int intHour = _timeValue/3600;
    int intMinute = _timeValue/60 - 60*intHour;
    int intSecond = _timeValue - intMinute*60 - intHour*3600;
    _timeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",intHour,intMinute,intSecond];
}



- (void)playAudioAction:(UIButton *)sender{
    
    //点击播放按钮，如果在播放则停止，否则继续播放
    if ([player isPlaying]) {
        //正在播放中，则停止
        [player pause];
    }else{
        //开始播放
        [player play];
    }
    
}


- (void)recordBtnPress:(UIButton *)sender{
    //录制按钮点击
    
    if (_isRecord == NO) {
        //开始录制
        _isRecord = YES;
        
        //调整视图
        [self updateViewsInRecodingStaute];
        
        //更新时间
        [self startUpdateTime];
        
        //初始化录制
        _audioRecoder = [[AVAudioRecorder alloc] initWithURL:recordedFile settings:nil error:nil];
        [_audioRecoder prepareToRecord];
        [_audioRecoder record];//开始录制
        
        //如果播放器在模仿中，则先取消停止
        if (player != nil) {
            [player stop];
            player = nil;
        }
        
    }else{
        //暂停录制
        
        _isRecord = NO;
        [_audioRecoder stop];
        _audioRecoder = nil;
        
        //调整视图
        [self updateViewsInFinfishStaute];
        
        //停止更新时间
        [self stopUpdateTime];
        
        //初始化播放器
        NSError *playerError;
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:recordedFile error:&playerError];
        
        if (player == nil)
        {
            NSLog(@"ERror creating player: %@", [playerError description]);
        }
        player.delegate = self;
    }
    
}


- (void)updateViewsInRecodingStaute{
    
    //调整在录制界面中的试图（取消和完成按钮不可以点击）
    [_recordBtn setImage:[UIImage imageNamed:@"audioManager_stopBtn"] forState:UIControlStateNormal];
    [_recordBtn setImage:[UIImage imageNamed:@"audioManager_stopBtn"] forState:UIControlStateSelected];
    [_recordBtn setImage:[UIImage imageNamed:@"audioManager_stopBtn"] forState:UIControlStateHighlighted];
    
    _cancelBtn.selected = YES;
    _cancelBtn.enabled = NO;
    _submitBtn.selected = YES;
    _submitBtn.enabled = NO;
    
}

- (void)updateViewsInFinfishStaute{
    
    //调整在完成录制后的视图
    [_recordBtn setImage:[UIImage imageNamed:@"audioManager_recordBtn"] forState:UIControlStateNormal];
    [_recordBtn setImage:[UIImage imageNamed:@"audioManager_recordBtn"] forState:UIControlStateSelected];
    [_recordBtn setImage:[UIImage imageNamed:@"audioManager_recordBtn"] forState:UIControlStateHighlighted];
    
    _cancelBtn.selected = NO;
    _cancelBtn.enabled = YES;
    _submitBtn.selected = NO;
    _submitBtn.enabled = YES;
    
}



- (void)closeCurrentView:(UIButton *)sender{
    //关闭当前界面
    [_backView removeFromSuperview];
    [_cancelBtn removeFromSuperview];
    [_submitBtn removeFromSuperview];
    [_recordBtn removeFromSuperview];
    [_navigationBar removeFromSuperview];
    [_timeLabel removeFromSuperview];
    [playBtn removeFromSuperview];
}


- (void)stopRecord{
    
    //停止录音，在取消和提交之前都需要停止录音
    //先停止录制
    [self stopUpdateTime];
    
    if (player != nil) {
        [player stop];
        player = nil;
    }
    
    if (_audioRecoder != nil) {
        [_audioRecoder stop];
        _audioRecoder = nil;
    }
    
    //关闭当前试图
    [self closeCurrentView:nil];
}

- (void)cancelCurrentView:(UIButton *)sender{
    
    //取消录制
    [self stopRecord];
}

- (void)recordFinished:(UIButton *)sender{
    
    //录制完成
    [self stopRecord];
    
    //文件保存本地
    
    //成功回调
    self.complete_Block(recordedFile.absoluteString,recordedFile.absoluteString);
}



#pragma mark - UIActionSheetDelegate methods
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (buttonIndex == 0) {
        //拍摄照片
        [self takeAudioFormRecord];
        return;
    }
    
    if (buttonIndex == 1) {
        //选取照片
        [self takeAudioFormAlbum];
        return;
    }
    
}


#pragma mark - MPMediaPickerControllerDelegate methods
- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection{
    //选取音频文件
    
//    MPMediaItem *item = [mediaItemCollection.items objectAtIndex:0];
//    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:[item valueForProperty:MPMediaItemPropertyAssetURL] options:nil];
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker{
    //取消选取音频文件
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
}

@end
