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
    
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    btn.backgroundColor = [UIColor cyanColor];
    [self.view addSubview:btn];
    [btn addTarget:self action:@selector(clickBtn) forControlEvents:UIControlEventTouchUpInside];
    
    
    
    ZHFloatItem *item1 = [ZHFloatItem new];
    item1.title = @"你好";
    item1.closeWhenTapClick = YES;
    item1.tapClickBlock = ^(ZHFloatItem *item) {
        NSLog(@"%@",item.title);
    };
    ZHFloatItem *item2 = [ZHFloatItem new];
    item2.title = @"啦啦啦啦啦啦啦啦啦啦啦啦";
    item2.tapClickBlock = ^(ZHFloatItem *item){
        NSLog(@"%@",item.title);
    };
    
    ZHFloatItem *item3 = [ZHFloatItem new];
    item3.title = @"三四";
    item3.tapClickBlock = ^(ZHFloatItem *item){
        NSLog(@"%@",item.title);
    };
    
    ZHFloatView *floatView = [ZHFloatView floatViewWithItems:@[item1, item2, item3]];
    floatView.tapClickBlock = ^{
        NSLog(@"---------tapClickBlock-----------");
    };
    [floatView updateTitle:@"刷新中..."];
    [floatView showInView:self.view location:ZHFloatLocationLeft locationScale:0.4];
    self.floatView = floatView;
    
    
    
    ZHFloatView *floatView1 = [ZHFloatView floatViewWithItems:nil];
    floatView1.tapClickBlock = ^{
        NSLog(@"---------tapClickBlock1-----------");
    };
    [floatView1 updateTitle:@"刷新中..."];
    [floatView1 showInView:self.view location:ZHFloatLocationLeft locationScale:0.6];

}

- (void)clickBtn{
    UINavigationBar *bar = self.navigationController.navigationBar;
    bar.translucent = !bar.translucent;
}

@end
