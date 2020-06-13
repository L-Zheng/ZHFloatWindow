//
//  ZHFloatView.m
//  ZHFloatWindow
//
//  Created by Zheng on 2020/3/28.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import "ZHFloatView.h"

@interface ZHFloatItem ()
@property (nonatomic, weak) ZHFloatItemView *itemView;
@end
@implementation ZHFloatItem
@end


@interface ZHFloatItemView ()

@property (nonatomic, weak) ZHFloatView *floatView;

@property (nonatomic,strong) ZHFloatItem *item;
@property (nonatomic,strong) UILabel *titleLabel;
@end
@implementation ZHFloatItemView

- (instancetype)initWithItem:(ZHFloatItem *)item{
    self = [super initWithFrame:(CGRect){CGPointZero, self.class.itemViewSize}];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:240.0/255.0 green:240.0/255.0 blue:240.0/255.0 alpha:1.0];
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = self.class.itemViewSize.width * 0.5;
        self.clipsToBounds = YES;
        
        [self updateItem:item];
        
        [self configGesture];
        
    }
    return self;
}
- (void)updateItem:(ZHFloatItem *)item{
    if (item == self.item || !item) return;
    self.item = item;
    item.itemView = self;
    
    UILabel *titleLabel = self.titleLabel;
    
    titleLabel.frame = self.bounds;
    titleLabel.text = item.title;
    if (!titleLabel.superview) {
        [self addSubview:titleLabel];
        return;
    }
    if (titleLabel.superview != self) {
        [titleLabel removeFromSuperview];
        [self addSubview:titleLabel];
    }
}

#pragma mark - gesture

- (void)configGesture{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureClick:)];
    [self addGestureRecognizer:tapGesture];
}

#pragma mark - action

- (void)tapGestureClick:(UITapGestureRecognizer *)gesture {
    if (!self.item.closeWhenTapClick) {
        if (self.item.tapClickBlock) self.item.tapClickBlock(self.item);
        return;
    }
    __weak __typeof__(self) __self = self;
    [self.floatView close:^{
        if (__self.item.tapClickBlock) __self.item.tapClickBlock(__self.item);
    }];
}

#pragma mark - getter

+ (CGSize)itemViewSize{
    return CGSizeMake(40, 40);
}
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
//        _titleLabel.font = [UIFont systemFontOfSize:12];
        _titleLabel.adjustsFontSizeToFitWidth = YES;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 0;
        _titleLabel.textColor = [UIColor blueColor];
        _titleLabel.backgroundColor = [UIColor clearColor];
    }
    return _titleLabel;
}
@end

@interface ZHFloatView ()<UIGestureRecognizerDelegate>

@property (nonatomic, assign, getter=isOpen) BOOL open;

@property (nonatomic,strong) NSMutableArray <ZHFloatItemView *> *itemViews;
@property (nonatomic,strong) NSMutableArray <ZHFloatItem *> *items;
@property (nonatomic,strong) UIButton *coverBtn;

@property (nonatomic,strong) UIImageView *imageView;
@property (nonatomic,strong) UILabel *titleLabel;
@property (nonatomic, assign) CGPoint startPoint;
@property (nonatomic, assign) CGRect startFrame;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) CGFloat timerCount;

@property (nonatomic, assign) ZHFloatLocation location;
@property (nonatomic, assign) CGFloat locationScale;
@end

@implementation ZHFloatView

#pragma mark - init

+ (ZHFloatView *)floatViewWithItems:(NSArray <ZHFloatItem *> *)items{
    ZHFloatView *floatView = [[ZHFloatView alloc] initWithFrame:CGRectZero];
    if (!items || ![items isKindOfClass:NSArray.class]) return floatView;
    
    floatView.items = [items mutableCopy];
    for (ZHFloatItem *item in items) {
        ZHFloatItemView *itemView = [[ZHFloatItemView alloc] initWithItem:item];
        itemView.floatView = floatView;
        [floatView.itemViews addObject:itemView];
    }
    return floatView;
}

- (void)showInView:(UIView *)view{
    [self showInView:view location:ZHFloatLocationRight];
}
- (void)showInView:(UIView *)view location:(ZHFloatLocation)location{
    [self showInView:view location:location locationScale:0.5];
}
- (void)showInView:(UIView *)view location:(ZHFloatLocation)location locationScale:(CGFloat)locationScale{
    if (!view) return;
    
    self.location = location;
    self.locationScale = (locationScale <= 0 || locationScale >= 1) ? 0.5 : locationScale;
    
    if (!self.superview) {
        [view addSubview:self];
    }else{
        if (![self.superview isEqual:view]) {
            [self removeFromSuperview];
            [view addSubview:self];
        }
    }
    [self updateWhenSuperViewLayout];
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        [self updateUINormal];
        [self addSubview:self.imageView];
        [self addSubview:self.titleLabel];
        
        [self configGesture];
    }
    return self;
}

- (void)updateWhenSuperViewLayout{
    UIView *view = self.superview;
    
    CGFloat superW = view.frame.size.width;
    CGFloat superH = view.frame.size.height;
    CGFloat selfW = self.selfSize.width;
    CGFloat selfH = self.selfSize.height;
    
    
    CGFloat X = 0;
    if (self.location == ZHFloatLocationRight) {
        X = superW - selfW;
    }else if (self.location == ZHFloatLocationLeft){
        X = 0;
    }
        
    self.frame = CGRectMake(X, (superH * self.locationScale - selfH * 0.5), selfW, selfH);
    
    if (![self.superview isEqual:view]) {
        [view addSubview:self];
    }
    [self moveToScreenEdge:^(CGRect currentFrame, ZHFloatLocation location) {
    }];
}

- (void)updateTitle:(NSString *)title{
    self.titleLabel.text = title;
}

#pragma mark - move

- (void)moveToScreenEdge:(void (^) (CGRect currentFrame, ZHFloatLocation location))finishBlock {
    //移动到屏幕边缘
    UIView *superview = self.superview;
    CGFloat superW = superview.frame.size.width;
    CGFloat superH = superview.frame.size.height;
    
    CGFloat leftCenterX = (self.frame.size.width * 0.5 + 0);
    CGFloat rightCenterX = superW - (self.frame.size.width * 0.5 + 0);
    CGFloat centerX = (self.center.x >= superW * 0.5) ? rightCenterX : leftCenterX;
    CGPoint targetCenter = CGPointMake(centerX, self.center.y);
    
    ZHFloatLocation location = superW == 0 ? self.location : ((self.center.x >= superW * 0.5) ? ZHFloatLocationRight : ZHFloatLocationLeft);
    
    if (CGPointEqualToPoint(targetCenter, self.center)) {
        self.location = location;
        if (superH > 0) {
            self.locationScale = targetCenter.y / superH;
        }
        if (finishBlock) finishBlock(self.frame, location);
        [self updateUIWhenAnimateEnd:location];
        return;
    }
    __weak __typeof__(self) weakSelf = self;
    [UIView animateWithDuration:0.25 animations:^{
        weakSelf.center = targetCenter;
        weakSelf.location = location;
        if (superH > 0) {
            weakSelf.locationScale = targetCenter.y / superH;
        }
        if (finishBlock) finishBlock(weakSelf.frame, location);
    } completion:^(BOOL finished) {
        [weakSelf updateUIWhenAnimateEnd:location];
    }];
}

#pragma mark - config

- (void)configGesture{
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureChanged:)];
    panGesture.delegate = self;
    [self addGestureRecognizer:panGesture];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureClick:)];
    tapGesture.delegate = self;
    [self addGestureRecognizer:tapGesture];
}

#pragma mark - UI

- (void)updateUIHigh{
    self.backgroundColor = [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1.0];
}

- (void)updateUINormal{
    self.backgroundColor = [UIColor colorWithRed:240.0/255.0 green:240.0/255.0 blue:240.0/255.0 alpha:1.0];
}

- (void)updateUIWhenPanGesBegan{
    CGFloat selfW = self.frame.size.width;
    CGFloat radius = self.frame.size.height * 0.5;
    
    UIBezierPath *maskPath = [UIBezierPath bezierPath];
    [maskPath moveToPoint:CGPointMake(selfW - radius, 0)];
    [maskPath addArcWithCenter:CGPointMake(selfW - radius, radius) radius:radius startAngle:M_PI + M_PI_2 endAngle:M_PI_2 clockwise:YES];
    [maskPath addArcWithCenter:CGPointMake(selfW - radius, radius) radius:radius startAngle:M_PI_2 endAngle:M_PI + M_PI_2 clockwise:YES];
    [maskPath addLineToPoint:CGPointMake(selfW - radius, 0)];
    [maskPath closePath];
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc]init];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    self.layer.mask = maskLayer;
}

- (void)updateUIWhenAnimateEnd:(ZHFloatLocation)location{
    CGFloat selfW = self.frame.size.width;
    CGFloat selfH = self.frame.size.height;
    CGFloat radius = self.frame.size.height * 0.5;
    
    UIBezierPath *maskPath = [UIBezierPath bezierPath];
    
    if (location == ZHFloatLocationLeft) {
        [maskPath moveToPoint:CGPointMake(0, 0)];
        [maskPath addLineToPoint:CGPointMake(selfW - radius, 0)];
        [maskPath addArcWithCenter:CGPointMake(selfW - radius, radius) radius:radius startAngle:M_PI + M_PI_2 endAngle:M_PI_2 clockwise:YES];
        [maskPath addLineToPoint:CGPointMake(0, selfH)];
        [maskPath addLineToPoint:CGPointMake(0, 0)];
    }else{
        [maskPath moveToPoint:CGPointMake(selfW, 0)];
        [maskPath addLineToPoint:CGPointMake(selfW, selfH)];
        [maskPath addLineToPoint:CGPointMake(selfW - radius, selfH)];
        [maskPath addArcWithCenter:CGPointMake(radius, radius) radius:radius startAngle:M_PI_2 endAngle:M_PI + M_PI_2 clockwise:YES];
        [maskPath addLineToPoint:CGPointMake(selfW, 0)];
    }
    [maskPath closePath];
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc]init];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    self.layer.mask = maskLayer;
    
    CGFloat imageViewW = 40;
    CGFloat imageViewH = 40;
    CGFloat margin = 10;
    self.imageView.layer.cornerRadius = imageViewW * 0.5;
    self.imageView.frame = CGRectMake((location == ZHFloatLocationRight ? margin : selfW - imageViewW - margin), (selfH - imageViewH) * 0.5, imageViewW, imageViewH);
    
    CGFloat labelW = self.titleLabelSize.width;
    CGFloat labelH = self.titleLabelSize.height;
    margin = 5;
    self.titleLabel.frame = CGRectMake((location == ZHFloatLocationRight ? margin : selfW - labelW - margin), (selfH - labelH) * 0.5, labelW, labelH);
}

#pragma mark - size

//展开半径
- (void)fetchOpenInfo:(void (^) (BOOL allow, CGFloat resAngle, CGFloat resRadius))callback{
    if (self.items.count == 0 || self.itemViews.count == 0) {
        if (callback) {
            callback(NO, 0, 0);
        }
        return;
    }
    CGFloat top = self.center.y;
    CGFloat bottom = self.superview.bounds.size.height - self.center.y;
    
    CGSize itemViewSize = [ZHFloatItemView itemViewSize];
    CGFloat defaultMaxRadius = self.selfSize.width * 0.5 + 30 + itemViewSize.width * 0.5;
    CGFloat defaultMinRadius = self.selfSize.width * 0.5 + 10 + itemViewSize.width * 0.5;
    
    //最大辐射长度
    CGFloat maxLength = defaultMaxRadius + itemViewSize.width * 0.5;
    CGFloat minLength = defaultMinRadius + itemViewSize.width * 0.5;
    //辐射角度
    CGFloat resAngle = 0;
    CGFloat resRadius = 0;
    
    if (top >= maxLength) {
        if (bottom >= maxLength) {
            resAngle = 180; resRadius = maxLength;
        }else if (bottom >= minLength && bottom < maxLength){
            resAngle = 180; resRadius = bottom;
        }else{
            //第一二象限 上方向
            resAngle = -90; resRadius = maxLength;
        }
    }else if (top >= minLength && top < maxLength){
        if (bottom >= maxLength) {
            resAngle = 180; resRadius = top;
        }else if (bottom >= minLength && bottom < maxLength){
            resAngle = 180; resRadius = MAX(top, bottom);
        }else{
            //第一二象限 上方向
            resAngle = -90; resRadius = top;
        }
    }else{
        if (bottom >= maxLength) {
            //第三四象限 下方向
            resAngle = 90; resRadius = maxLength;
        }else if (bottom >= minLength && bottom < maxLength){
            //第三四象限 下方向
            resAngle = 90; resRadius = bottom;
        }else{
            //空间太小 不给展开
            resAngle = 0; resRadius = 0;
        }
    }
    if (callback) {
        callback(!(resAngle == 0 || resRadius == 0), resAngle, resRadius - [ZHFloatItemView itemViewSize].height * 0.5);
    }
}

- (CGSize)selfSize{
    return CGSizeMake(60, 60);
}

- (CGSize)titleLabelSize{
    return CGSizeMake(50, 50);
}

#pragma mark - action
- (void)open:(void (^) (void))completion{
    if (!self.isOpen) {
        [self openInternal:completion];
        return;
    }
    if (completion) completion();
}
- (void)close:(void (^) (void))completion{
    [self closeInternal:completion];
}

- (void)tapGestureClick:(UITapGestureRecognizer *)gesture {
    [self handleTapGestureClick];
}
- (void)handleTapGestureClick{
    __weak __typeof__(self) __self = self;
    if (!self.isOpen) {
        [self openInternal:^{
            if (__self.tapClickBlock) __self.tapClickBlock();
        }];
        return;
    }
    [self closeInternal:^{
        if (__self.tapClickBlock) __self.tapClickBlock();
    }];
}

- (void)panGestureChanged:(UIPanGestureRecognizer *)gesture {
    
    UIView *superview = self.superview;
    CGFloat superW = superview.frame.size.width;
    CGFloat superH = superview.frame.size.height;
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self removeTimer];
        self.startPoint = [gesture locationInView:superview];
        self.startFrame = self.frame;
        [self handlePanGestureBegan];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        
        CGPoint p = [gesture locationInView:superview];
        CGFloat offsetX = p.x - self.startPoint.x;
        CGFloat offSetY = p.y - self.startPoint.y;
        
        CGFloat width = self.frame.size.width;
        CGFloat height = self.frame.size.height;
        //限制拖动范围
        CGFloat X = self.startFrame.origin.x + offsetX;
        if (X <= 0) X = 0;
        if (X >= superW - width) X = superW - width;
        
        CGFloat Y = self.startFrame.origin.y + offSetY;
        if (Y <= 0) Y = 0;
        if (Y >= superH - height) Y = superH - height;
        
        self.frame = (CGRect){{X, Y}, self.frame.size};
        
        //检查是否进入删除区域
        [self handlePanGestureChanged:self.frame];
        
    } else if (gesture.state == UIGestureRecognizerStateEnded ||
              gesture.state == UIGestureRecognizerStateCancelled ||
              gesture.state == UIGestureRecognizerStateFailed) {
        [self handlePanGestureEnd];
    }
}
- (void)handlePanGestureBegan{
    [self updateUIWhenPanGesBegan];
//    NSLog(@"-------%s---------", __func__);
    if (self.panGestureBegan) self.panGestureBegan();
}
- (void)handlePanGestureChanged:(CGRect)frame{
//    NSLog(@"-------%s---------", __func__);
    if (self.panGestureChanged) self.panGestureChanged(self.frame);
}
- (void)handlePanGestureEnd{
//    NSLog(@"-------%s---------", __func__);
    if (self.panGestureEnd) self.panGestureEnd();
    [self moveToScreenEdge:^(CGRect currentFrame, ZHFloatLocation location) {
        
    }];
}

- (void)coverBtnClick{
    [self closeInternal:nil];
}

- (void)openInternal:(void (^) (void))completion{
    [self updateUIHigh];
    // 展开
    __weak __typeof__(self) __self = self;
    [self fetchOpenInfo:^(BOOL allow, CGFloat resAngle, CGFloat resRadius) {
        if (!allow) {
            // 没有子items or 空间太小放不下 不展开
            [__self performSelector:@selector(updateUINormal) withObject:nil afterDelay:0.25];
            if (completion) completion();
            return;
        }
        
        if (__self.isOpen) {
            if (completion) completion();
            return;
        }
        __self.open = YES;
        
        [__self opCoverBtn:YES duration:0.25];
        [__self opItemViews:YES resAngle:resAngle resRadius:resRadius duration:0.25 completion:^{
            if (completion) completion();
        }];
    }];
}
- (void)closeInternal:(void (^) (void))completion{
    if (!self.isOpen) {
        if (completion) completion();
        return;
    }
    self.open = NO;
    
    [self updateUINormal];
    [self opCoverBtn:NO duration:0.25];
    [self opItemViews:NO resAngle:0 resRadius:0 duration:0.25 completion:^{
        if (completion) completion();
    }];
}

- (void)resetItemViewsFrame:(BOOL)isOpen duration:(NSTimeInterval)duration completion:(void (^) (void))completion{
    if (isOpen) {
        for (ZHFloatItemView *itemView in self.itemViews) {
            itemView.center = self.center;
            [self.coverBtn addSubview:itemView];
        }
        if (completion) completion();
        return;
    }
    [UIView animateWithDuration:duration animations:^{
        for (ZHFloatItemView *itemView in self.itemViews) {
            itemView.center = self.center;
        }
    } completion:^(BOOL finished) {
        [self.itemViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        if (completion) completion();
    }];
}

- (void)opItemViews:(BOOL)isOpen resAngle:(CGFloat)resAngle resRadius:(CGFloat)resRadius duration:(NSTimeInterval)duration completion:(void (^) (void))completion{
    if (!isOpen) {
        [self resetItemViewsFrame:NO duration:duration completion:^{
            if (completion) completion();
        }];
        return;
    }
    //计算角度
    CGFloat averageAngle = fabs(resAngle) * 1.0 / ((self.itemViews.count + 1) * 1.0);
    double averageHuAngle = M_PI / (180.0 / averageAngle);
    NSMutableArray <NSValue *> *centers = [@[] mutableCopy];
    
    double startHuAngle = 0;
    if (resAngle == 180) {
        startHuAngle = 0;
    }else if (resAngle == 90){
        startHuAngle = M_PI_2;
    }else if (resAngle == -90){
        startHuAngle = 0;
    }
    // 保留相对于 辐射圆上顶点 的坐标
    for (NSUInteger i = 0; i < self.itemViews.count; i++) {
        CGFloat X = sin(startHuAngle + averageHuAngle * (i + 1)) * resRadius;
        if (self.location == ZHFloatLocationRight) {
            X = -X;
        }
        CGFloat Y = resRadius - cos(startHuAngle + averageHuAngle * (i + 1)) * resRadius;
        [centers addObject:[NSValue valueWithCGPoint:CGPointMake(X, Y)]];
    }
    
    //重置位置
    [self resetItemViewsFrame:YES duration:duration completion:nil];
    
    [UIView animateWithDuration:duration animations:^{
        for (NSUInteger i = 0; i < self.itemViews.count; i++) {
            ZHFloatItemView *itemView = self.itemViews[i];
            CGFloat X = self.center.x + centers[i].CGPointValue.x;
            CGFloat Y = self.center.y - resRadius + centers[i].CGPointValue.y;
            itemView.center = CGPointMake(X, Y);
        }
    } completion:^(BOOL finished) {
        if (completion) completion();
    }];
}

- (void)opCoverBtn:(BOOL)isOpen duration:(NSTimeInterval)duration{
    if (isOpen) {
        self.coverBtn.alpha = 0.0;
        self.coverBtn.frame = self.superview.bounds;
        [self.superview insertSubview:self.coverBtn belowSubview:self];
        [UIView animateWithDuration:duration animations:^{
            self.coverBtn.alpha = 0.5;
        } completion:^(BOOL finished) {
            
        }];
        return;
    }
    [UIView animateWithDuration:duration animations:^{
        self.coverBtn.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.coverBtn removeFromSuperview];
    }];
}

#pragma mark - timer

- (void)addTimer {
    if (self.timer) return;
    self.timerCount = 0;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerResponded) userInfo:nil repeats:YES];
}

- (void)removeTimer {
    if (!self.timer) return;
    [self.timer invalidate];
    self.timer = nil;
    self.timerCount = 0;
}

- (void)timerResponded {
    self.timerCount += 0.1;
    if (self.timerCount >= 0.5) {
        [self removeTimer];
        [self handlePanGestureBegan];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    NSLog(@"-------%s---------", __func__);
    [super touchesBegan:touches withEvent:event];
    [self addTimer];
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    NSLog(@"-------%s---------", __func__);
    [super touchesEnded:touches withEvent:event];
    [self removeTimer];
    [self handlePanGestureEnd];
}

//可能被tap or 拖拽手势中断
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    NSLog(@"-------%s---------", __func__);
    [super touchesCancelled:touches withEvent:event];
    [self removeTimer];
}

#pragma mark - getter

- (UIImageView *)imageView{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.backgroundColor = [UIColor clearColor];
        _imageView.image = [UIImage imageNamed:@"applet-icon"];
    }
    return _imageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont systemFontOfSize:12];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 0;
        _titleLabel.textColor = [UIColor blueColor];
        _titleLabel.backgroundColor = [UIColor clearColor];
    }
    return _titleLabel;
}

- (UIView *)coverBtn{
    if (!_coverBtn) {
        _coverBtn = [[UIButton alloc] init];
        _coverBtn.backgroundColor = [UIColor blackColor];
        [_coverBtn addTarget:self action:@selector(coverBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _coverBtn;
}

- (NSMutableArray<ZHFloatItemView *> *)itemViews{
    if (!_itemViews) {
        _itemViews = [@[] mutableCopy];
    }
    return _itemViews;
}
@end
