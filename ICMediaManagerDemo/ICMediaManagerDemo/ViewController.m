//
//  ViewController.m
//  ICMediaManagerDemo
//
//  Created by Fox on 14-4-22.
//  Copyright (c) 2014年 Fox. All rights reserved.
//

#import "ViewController.h"
#import "ICImagePickerManager.h"

@interface ViewController ()
- (IBAction)selectPicAction:(id)sender;
@property (strong, nonatomic) IBOutlet UIImageView *resultImage;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)selectPicAction:(id)sender {
    
    [[ICImagePickerManager shareInstance] imagePickerWithType:ICImagePickerStyleTypeBoth enableEditing:YES withDelegate:self comleteBlock:^(UIImage *resultImage, UIImage *orignImage) {
        self.resultImage.image = resultImage;
    } failedBlock:^(NSError *error) {
        
    }];
    
}
@end
