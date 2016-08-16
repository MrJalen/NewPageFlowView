//
//  NewPageFlowView.m
//  NewPageFlowView
//
//  Created by MrJalen on 16/8/4.
//  Copyright © 2016年 lianjiang. All rights reserved.
//

#import "NewPageFlowView.h"
#import "BannerIndexView.h"

@interface NewPageFlowView ()

/** 当前页数 */
@property (nonatomic, assign, readwrite) NSInteger currentPageIndex;

/** 计时器用到的页数 */
@property (nonatomic, assign) NSInteger page;

/** 原始页数 */
@property (nonatomic, assign) NSInteger orginPageCount;

@end

@implementation NewPageFlowView

//============================== 私有方法 ==============================//
#pragma mark -
#pragma mark Private Methods
- (void)initialize{
    self.clipsToBounds = YES;

    self.needsReload = YES;// 是否需要重新加载
    self.pageSize = self.bounds.size;// 单页size
    self.pageCount = 0;// 总页数
    _currentPageIndex = 0;

    _minimumPageAlpha = 1.0;
    _minimumPageScale = 1.0;
    _autoTime = 5.0;

    self.visibleRange = NSMakeRange(0, 0);// 可见范围

    self.reusableCells = [[NSMutableArray alloc] initWithCapacity:0];
    self.cells = [[NSMutableArray alloc] initWithCapacity:0];

    self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.scrollView.scrollsToTop = NO;
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.clipsToBounds = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;

    /** 由于UIScrollView在滚动之后会调用自己的layoutSubviews以及父View的layoutSubviews
     *  这里为了避免scrollview滚动带来自己layoutSubviews的调用,所以给scrollView加了一层父View
     */
    UIView *superViewOfScrollView = [[UIView alloc] initWithFrame:self.bounds];
    [superViewOfScrollView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [superViewOfScrollView setBackgroundColor:[UIColor clearColor]];
    [superViewOfScrollView addSubview:self.scrollView];
    [self addSubview:superViewOfScrollView];

}

/** 开启定时器 */
- (void)startTimer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.autoTime target:self selector:@selector(autoNextPage) userInfo:nil repeats:YES];
}

/** 关闭定时器 */
- (void)stopTimer {
    [self.timer invalidate];
}

#pragma mark --自动轮播
- (void)autoNextPage {
    self.page ++;
    [_scrollView setContentOffset:CGPointMake(self.page * _pageSize.width, 0) animated:YES];
}

/** 添加到可重用队列中 */
- (void)queueReusableCell:(UIView *)cell{
    [_reusableCells addObject:cell];
}

/** 移除index相应的Cell */
- (void)removeCellAtIndex:(NSInteger)index{
    UIView *cell = [_cells objectAtIndex:index];
    if ((NSObject *)cell == [NSNull null]) {
        return;
    }

    [self queueReusableCell:cell];

    if (cell.superview) {
        [cell removeFromSuperview];
    }
    [_cells replaceObjectAtIndex:index withObject:[NSNull null]];
}

- (void)refreshVisibleCellAppearance {
    if (_minimumPageAlpha == 1.0 && _minimumPageScale == 1.0) {
        return;//无需更新
    }
    switch (self.orientation) {
        case NewPageFlowViewOrientationHorizontal:{
            CGFloat offset = _scrollView.contentOffset.x;
            for (NSInteger i = self.visibleRange.location; i < self.visibleRange.location + _visibleRange.length; i++) {
                BannerIndexView *cell = [_cells objectAtIndex:i];
                CGFloat origin = cell.frame.origin.x;
                CGFloat delta = fabs(origin - offset);

                CGRect originCellFrame = CGRectMake(_pageSize.width * i, 0, _pageSize.width, _pageSize.height);//如果没有缩小效果的情况下的本该的Frame

                if (delta < _pageSize.width) {

                    cell.coverView.alpha = (delta / _pageSize.width) * (1 - _minimumPageAlpha);

                    CGFloat inset = (_pageSize.width * (1 - _minimumPageScale)) * (delta / _pageSize.width)/2.0;
                    cell.frame = UIEdgeInsetsInsetRect(originCellFrame, UIEdgeInsetsMake(inset, inset, inset, inset));
                } else {

                    cell.coverView.alpha = _minimumPageAlpha;
                    CGFloat inset = _pageSize.width * (1 - _minimumPageScale) / 2.0 ;
                    cell.frame = UIEdgeInsetsInsetRect(originCellFrame, UIEdgeInsetsMake(inset, inset, inset, inset));
                }

            }
            break;
        }
        case NewPageFlowViewOrientationVertical:{
            CGFloat offset = _scrollView.contentOffset.y;

            for (NSInteger i = self.visibleRange.location; i < self.visibleRange.location + _visibleRange.length; i++) {
                BannerIndexView *cell = [_cells objectAtIndex:i];
                CGFloat origin = cell.frame.origin.y;
                CGFloat delta = fabs(origin - offset);

                CGRect originCellFrame = CGRectMake(0, _pageSize.height * i, _pageSize.width, _pageSize.height);//如果没有缩小效果的情况下的本该的Frame

                if (delta < _pageSize.height) {
                    cell.coverView.alpha = 1 - (delta / _pageSize.height) * (1 - _minimumPageAlpha);

                    CGFloat inset = (_pageSize.height * (1 - _minimumPageScale)) * (delta / _pageSize.height)/2.0;
                    cell.frame = UIEdgeInsetsInsetRect(originCellFrame, UIEdgeInsetsMake(inset, inset, inset, inset));
                } else {
                    cell.coverView.alpha = _minimumPageAlpha;
                    CGFloat inset = _pageSize.height * (1 - _minimumPageScale) / 2.0 ;
                    cell.frame = UIEdgeInsetsInsetRect(originCellFrame, UIEdgeInsetsMake(inset, inset, inset, inset));
                }

            }
        }
        default:
            break;
    }

}

- (void)setPageAtIndex:(NSInteger)pageIndex {
    NSParameterAssert(pageIndex >= 0 && pageIndex < [_cells count]);

    UIView *cell = [_cells objectAtIndex:pageIndex];

    if ((NSObject *)cell == [NSNull null]) {
        cell = [_dataSource flowView:self cellForPageAtIndex:pageIndex % self.orginPageCount];
        NSAssert(cell!=nil, @"datasource must not return nil");
        [_cells replaceObjectAtIndex:pageIndex withObject:cell];


        switch (self.orientation) {
            case NewPageFlowViewOrientationHorizontal:
                cell.frame = CGRectMake(_pageSize.width * pageIndex, 0, _pageSize.width, _pageSize.height);
                break;
            case NewPageFlowViewOrientationVertical:
                cell.frame = CGRectMake(0, _pageSize.height * pageIndex, _pageSize.width, _pageSize.height);
                break;
            default:
                break;
        }

        if (!cell.superview) {
            [_scrollView addSubview:cell];
        }
    }
}


- (void)setPagesAtContentOffset:(CGPoint)offset{
    //计算_visibleRange
    CGPoint startPoint = CGPointMake(offset.x - _scrollView.frame.origin.x, offset.y - _scrollView.frame.origin.y);
    CGPoint endPoint = CGPointMake(startPoint.x + self.bounds.size.width, startPoint.y + self.bounds.size.height);


    switch (self.orientation) {
        case NewPageFlowViewOrientationHorizontal:{
            NSInteger startIndex = 0;
            for (int i =0; i < [_cells count]; i++) {
                if (_pageSize.width * (i +1) > startPoint.x) {
                    startIndex = i;
                    break;
                }
            }

            NSInteger endIndex = startIndex;
            for (NSInteger i = startIndex; i < [_cells count]; i++) {
                //如果都不超过则取最后一个
                if ((_pageSize.width * (i + 1) < endPoint.x && _pageSize.width * (i + 2) >= endPoint.x) || i+ 2 == [_cells count]) {
                    endIndex = i + 1;//i+2 是以个数，所以其index需要减去1
                    break;
                }
            }

            //可见页分别向前向后扩展一个，提高效率
            startIndex = MAX(startIndex - 1, 0);
            endIndex = MIN(endIndex + 1, [_cells count] - 1);

            self.visibleRange = NSMakeRange(startIndex, endIndex - startIndex + 1);
            for (NSInteger i = startIndex; i <= endIndex; i++) {
                [self setPageAtIndex:i];
            }

            for (int i = 0; i < startIndex; i ++) {
                [self removeCellAtIndex:i];
            }

            for (NSInteger i = endIndex + 1; i < [_cells count]; i ++) {
                [self removeCellAtIndex:i];
            }
            break;
        }
        case NewPageFlowViewOrientationVertical:{
            NSInteger startIndex = 0;
            for (int i =0; i < [_cells count]; i++) {
                if (_pageSize.height * (i +1) > startPoint.y) {
                    startIndex = i;
                    break;
                }
            }

            NSInteger endIndex = startIndex;
            for (NSInteger i = startIndex; i < [_cells count]; i++) {
                //如果都不超过则取最后一个
                if ((_pageSize.height * (i + 1) < endPoint.y && _pageSize.height * (i + 2) >= endPoint.y) || i+ 2 == [_cells count]) {
                    endIndex = i + 1;//i+2 是以个数，所以其index需要减去1
                    break;
                }
            }

            //可见页分别向前向后扩展一个，提高效率
            startIndex = MAX(startIndex - 1, 0);
            endIndex = MIN(endIndex + 1, [_cells count] - 1);

            _visibleRange.location = startIndex;
            _visibleRange.length = endIndex - startIndex + 1;

            for (NSInteger i = startIndex; i <= endIndex; i++) {
                [self setPageAtIndex:i];
            }

            for (int i = 0; i < startIndex; i ++) {
                [self removeCellAtIndex:i];
            }

            for (NSInteger i = endIndex + 1; i < [_cells count]; i ++) {
                [self removeCellAtIndex:i];
            }
            break;
        }
        default:
            break;
    }
}

//============================== 重写（覆盖）方法 ==============================//
#pragma mark -
#pragma mark Override Methods

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];

    if (_needsReload) {
        //如果需要重新加载数据，则需要清空相关数据全部重新加载
        //重置pageCount
        if (_dataSource && [_dataSource respondsToSelector:@selector(numberOfPagesInFlowView:)]) {
            //总页数
            _pageCount = [_dataSource numberOfPagesInFlowView:self] * 3;

            //原始页数
            self.orginPageCount = [_dataSource numberOfPagesInFlowView:self];

            if (self.pageControl && [self.pageControl respondsToSelector:@selector(setNumberOfPages:)]) {
                [self.pageControl setNumberOfPages:self.orginPageCount];
            }
        }

        //重置pageWidth
        if (_delegate && [_delegate respondsToSelector:@selector(sizeForPageInFlowView:)]) {
            _pageSize = [_delegate sizeForPageInFlowView:self];
        }

        [_reusableCells removeAllObjects];
        _visibleRange = NSMakeRange(0, 0);

        //填充cells数组
        [_cells removeAllObjects];
        for (NSInteger index=0; index<_pageCount; index++) {
            [_cells addObject:[NSNull null]];
        }

        // 重置_scrollView的contentSize
        switch (self.orientation) {
            case NewPageFlowViewOrientationHorizontal://横向
                _scrollView.frame = CGRectMake(0, 0, _pageSize.width, _pageSize.height);
                _scrollView.contentSize = CGSizeMake(_pageSize.width * _pageCount,_pageSize.height);
                CGPoint theCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
                _scrollView.center = theCenter;

                if (self.orginPageCount > 1) {
                    //滚到第二组
                    [_scrollView setContentOffset:CGPointMake(_pageSize.width * self.orginPageCount, 0) animated:NO];

                    self.page = self.orginPageCount;
                }

                break;
            case NewPageFlowViewOrientationVertical:{
                _scrollView.frame = CGRectMake(0, 0, _pageSize.width, _pageSize.height);
                _scrollView.contentSize = CGSizeMake(_pageSize.width ,_pageSize.height * _pageCount);
                CGPoint theCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
                _scrollView.center = theCenter;

                if (self.orginPageCount > 1) {
                    //滚到第二组
                    [_scrollView setContentOffset:CGPointMake(0, _pageSize.height * self.orginPageCount) animated:NO];

                    self.page = self.orginPageCount;
                }

                break;
            }
            default:
                break;
        }
    }
    [self setPagesAtContentOffset:_scrollView.contentOffset];//根据当前scrollView的offset设置cell
    [self refreshVisibleCellAppearance];//更新各个可见Cell的显示外貌
}

#pragma mark -
#pragma mark NewPageFlowView API
- (void)reloadData {
    _needsReload = YES;
    [self setNeedsLayout];
}

- (UIView *)dequeueReusableCell {
    BannerIndexView *cell = [_reusableCells lastObject];
    if (cell) {
        [_reusableCells removeLastObject];
    }

    return cell;
}

- (void)scrollToPage:(NSUInteger)pageNumber {
    if (pageNumber < _pageCount) {
        switch (self.orientation) {
            case NewPageFlowViewOrientationHorizontal:
                [_scrollView setContentOffset:CGPointMake(_pageSize.width * pageNumber, 0) animated:YES];
                break;
            case NewPageFlowViewOrientationVertical:
                [_scrollView setContentOffset:CGPointMake(0, _pageSize.height * pageNumber) animated:YES];
                break;
        }
        [self setPagesAtContentOffset:_scrollView.contentOffset];
        [self refreshVisibleCellAppearance];
    }
}

#pragma mark -
#pragma mark hitTest 冲击测试

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if ([self pointInside:point withEvent:event]) {
        CGPoint newPoint = CGPointZero;
        newPoint.x = point.x - _scrollView.frame.origin.x + _scrollView.contentOffset.x;
        newPoint.y = point.y - _scrollView.frame.origin.y + _scrollView.contentOffset.y;
        if ([_scrollView pointInside:newPoint withEvent:event]) {
            return [_scrollView hitTest:newPoint withEvent:event];
        }

        return _scrollView;
    }
    return nil;
}


#pragma mark -
#pragma mark UIScrollView Delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{

    // NSLog(@"%f",scrollView.contentOffset.x / _pageSize.width);
    NSInteger pageIndex;

    switch (self.orientation) {
        case NewPageFlowViewOrientationHorizontal:
            pageIndex = (int)floor(_scrollView.contentOffset.x / _pageSize.width) % self.orginPageCount;
            break;
        case NewPageFlowViewOrientationVertical:
            pageIndex = (int)floor(_scrollView.contentOffset.y / _pageSize.height) % self.orginPageCount;
            break;
        default:
            break;
    }

    if (self.orginPageCount > 1) {
        switch (self.orientation) {
            case NewPageFlowViewOrientationHorizontal:
            {
                if (scrollView.contentOffset.x / _pageSize.width >= 2 * self.orginPageCount) {

                    [scrollView setContentOffset:CGPointMake(_pageSize.width * self.orginPageCount, 0) animated:NO];

                    self.page = self.orginPageCount;
                }

                if (scrollView.contentOffset.x / _pageSize.width <= self.orginPageCount - 1) {
                    [scrollView setContentOffset:CGPointMake((2 * self.orginPageCount - 1) * _pageSize.width, 0) animated:NO];

                    self.page = 2 * self.orginPageCount;
                }
            }
                break;
            case NewPageFlowViewOrientationVertical:
            {
                if (scrollView.contentOffset.y / _pageSize.height >= 2 * self.orginPageCount) {

                    [scrollView setContentOffset:CGPointMake(_pageSize.height * self.orginPageCount, 0) animated:NO];

                    self.page = self.orginPageCount;
                }

                if (scrollView.contentOffset.y / _pageSize.height <= self.orginPageCount - 1) {
                    [scrollView setContentOffset:CGPointMake((2 * self.orginPageCount - 1) * _pageSize.height, 0) animated:NO];
                    self.page = 2 * self.orginPageCount;
                }
            }
                break;
            default:
                break;
        }
    }else {
        pageIndex = 0;
    }

    [self setPagesAtContentOffset:scrollView.contentOffset];
    [self refreshVisibleCellAppearance];

    if (self.pageControl && [self.pageControl respondsToSelector:@selector(setCurrentPage:)]) {
        [self.pageControl setCurrentPage:pageIndex];
    }

    if ([_delegate respondsToSelector:@selector(didScrollToPage:inFlowView:)] && _currentPageIndex != pageIndex) {
        [_delegate didScrollToPage:pageIndex inFlowView:self];
    }

    _currentPageIndex = pageIndex;
}

#pragma mark --将要开始拖拽
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.timer invalidate];
}

#pragma mark --将要结束拖拽
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (self.orginPageCount > 1) {

        self.timer = [NSTimer scheduledTimerWithTimeInterval:self.autoTime target:self selector:@selector(autoNextPage) userInfo:nil repeats:YES];
        switch (self.orientation) {
            case NewPageFlowViewOrientationHorizontal:
            {
                if (self.page == floor(_scrollView.contentOffset.x / _pageSize.width)) {

                    self.page = floor(_scrollView.contentOffset.x / _pageSize.width) + 1;
                }else {

                    self.page = floor(_scrollView.contentOffset.x / _pageSize.width);
                }
            }
                break;
            case NewPageFlowViewOrientationVertical:
            {
                if (self.page == floor(_scrollView.contentOffset.y / _pageSize.height)) {

                    self.page = floor(_scrollView.contentOffset.y / _pageSize.height) + 1;
                }else {

                    self.page = floor(_scrollView.contentOffset.y / _pageSize.height);
                }
            }
                break;
            default:
                break;
        }
    }
}

@end

