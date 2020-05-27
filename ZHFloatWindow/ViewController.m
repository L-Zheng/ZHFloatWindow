//
//  ViewController.m
//  ZHFloatWindow
//
//  Created by Zheng on 2020/3/28.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ViewController.h"
#import "ZHFloatView.h"

@interface ViewController ()
@property (nonatomic, strong) ZHFloatView *floatView;
@end

@implementation ViewController

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    [self.floatView updateWhenSuperViewLayout];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    ZHFloatView *floatView = [ZHFloatView floatView];
    floatView.tapClickBlock = ^{
        NSLog(@"---------tapClickBlock-----------");
    };
    [floatView updateTitle:@"刷新中..."];
    [floatView showInView:self.view location:ZHFloatLocationLeft];
    self.floatView = floatView;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UINavigationBar *bar = self.navigationController.navigationBar;
        bar.translucent = NO;
    });
}


@end
