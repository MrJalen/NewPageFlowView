//
//  NewPageFlowView.h
//  NewPageFlowView
//
//  Created by MrJalen on 16/8/4.
//  Copyright © 2016年 lianjiang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NewPageFlowViewDataSource;
@protocol NewPageFlowViewDelegate;

typedef enum{
    NewPageFlowViewOrientationHorizontal = 0,
    NewPageFlowViewOrientationVertical
}NewPageFlowViewOrientation;

@interface NewPageFlowView : UIView <UIScrollViewDelegate>

@property (nonatomic, assign) NewPageFlowViewOrientation orientation;//默认为横向

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, assign) BOOL needsReload;
@property (nonatomic, assign) CGSize pageSize; //一页的尺寸
@property (nonatomic, assign) NSInteger pageCount;  //总页数

@property (nonatomic, strong) NSMutableArray *cells;
@property (nonatomic, assign) NSRange visibleRange; // 可见范围
@property (nonatomic, strong) NSMutableArray *reusableCells;//如果以后需要支持reuseIdentifier，这边就得使用字典类型了

@property (nonatomic, assign) id <NewPageFlowViewDataSource> dataSource;
@property (nonatomic, assign) id <NewPageFlowViewDelegate>   delegate;

/** 指示器 */
@property (nonatomic,retain)  UIPageControl *pageControl;

/** 非当前页的透明比例 */
@property (nonatomic, assign) CGFloat minimumPageAlpha;

/** 非当前页的缩放比例 */
@property (nonatomic, assign) CGFloat minimumPageScale;

/** 当前是第几页 */
@property (nonatomic, assign, readonly) NSInteger currentPageIndex;

/** 定时器 */
@property (nonatomic, weak) NSTimer *timer;

/** 自动切换视图的时间,默认是5.0 */
@property (nonatomic, assign) CGFloat autoTime;


- (void)reloadData;

/**
 *  获取可重复使用的Cell
 */
- (UIView *)dequeueReusableCell;

/**
 *  滚动到指定的页面
 */
- (void)scrollToPage:(NSUInteger)pageNumber;

/**
 *  开启定时器
 */
- (void)startTimer;

/**
 *  关闭定时器
 */
- (void)stopTimer;

@end


@protocol  NewPageFlowViewDelegate <NSObject>

/**
 *  单个子控件的Size
 */
- (CGSize)sizeForPageInFlowView:(NewPageFlowView *)flowView;

@optional

/**
 *  滚动到了某一列
 */
- (void)didScrollToPage:(NSInteger)pageNumber inFlowView:(NewPageFlowView *)flowView;

@end


@protocol NewPageFlowViewDataSource <NSObject>

/**
 *  返回显示View的个数
 */
- (NSInteger)numberOfPagesInFlowView:(NewPageFlowView *)flowView;

/**
 *  给某一列设置属性
 */
- (UIView *)flowView:(NewPageFlowView *)flowView cellForPageAtIndex:(NSInteger)index;

@end
