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
    
    self.view.backgroundColor = [UIColor orangeColor];
    
    ZHFloatView *floatView = [ZHFloatView floatView];
    floatView.tapClickBlock = ^{
        NSLog(@"---------tapClickBlock-----------");
    };
    [floatView updateTitle:@"刷新中..."];
    [floatView showInView:self.view location:ZHFloatLocationLeft locationScale:0.4];
    self.floatView = floatView;
    
    
    
    ZHFloatView *floatView1 = [ZHFloatView floatView];
    floatView1.tapClickBlock = ^{
        NSLog(@"---------tapClickBlock-----------");
    };
    [floatView1 updateTitle:@"刷新中..."];
    [floatView1 showInView:self.view location:ZHFloatLocationLeft locationScale:0.6];
    
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    btn.backgroundColor = [UIColor cyanColor];
    [self.view addSubview:btn];
    [btn addTarget:self action:@selector(clickBtn) forControlEvents:UIControlEventTouchUpInside];

}

- (void)clickBtn{
    UINavigationBar *bar = self.navigationController.navigationBar;
    bar.translucent = !bar.translucent;
}

@end
