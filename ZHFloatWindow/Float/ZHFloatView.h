//
//  ZHFloatView.h
//  ZHFloatWindow
//
//  Created by Zheng on 2020/3/28.
//  Copyright © 2020 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

//NS_ASSUME_NONNULL_BEGIN

@interface ZHFloatItem : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) BOOL closeWhenTapClick;
@property (nonatomic, copy) void (^tapClickBlock) (ZHFloatItem *item);
@end

@interface ZHFloatItemView : UIView
- (instancetype)initWithItem:(ZHFloatItem *)item;
@end


typedef NS_ENUM(NSInteger, ZHFloatLocation) {
    ZHFloatLocationLeft     = 0,
    ZHFloatLocationRight      = 1,
};
@interface ZHFloatView : UIView

+ (ZHFloatView *)floatViewWithItems:(NSArray <ZHFloatItem *> *)items;
- (void)showInView:(UIView *)view;
- (void)showInView:(UIView *)view location:(ZHFloatLocation)location;
- (void)showInView:(UIView *)view location:(ZHFloatLocation)location locationScale:(CGFloat)locationScale;

- (void)updateWhenSuperViewLayout;
- (void)updateTitle:(NSString *)title;

@property (nonatomic, assign, readonly, getter=isOpen) BOOL open;
@property (nonatomic, copy) void (^tapClickBlock) (void);
@property (nonatomic, copy) void (^panGestureBegan) (void);
@property (nonatomic, copy) void (^panGestureChanged) (CGRect currentFrame);
@property (nonatomic, copy) void (^panGestureEnd) (void);

- (void)open:(void (^) (void))completion;
- (void)close:(void (^) (void))completion;
@end

//NS_ASSUME_NONNULL_END
