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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    ZHFloatView *floatView = [ZHFloatView floatView];
    floatView.tapClickBlock = ^{
        NSLog(@"---------tapClickBlock-----------");
    };
    [floatView updateTitle:@"刷新中..."];
    [floatView showInView:self.view];
}


@end
