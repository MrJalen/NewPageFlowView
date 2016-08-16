//
//  BannerIndexView.m
//  NewPageFlowView
//
//  Created by MrJalen on 16/8/4.
//  Copyright © 2016年 lianjiang. All rights reserved.
//

#import "BannerIndexView.h"

@implementation BannerIndexView

/** 初始化 */
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        [self addSubview:self.mainImageView];
        [self addSubview:self.coverView];
        [self addSubview:self.allCoverButton];
    }

    return self;
}

- (UIImageView *)mainImageView {
    if (_mainImageView == nil) {
        _mainImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    }
    return _mainImageView;
}

- (UIView *)coverView {
    if (_coverView == nil) {
        _coverView = [[UIView alloc] initWithFrame:self.bounds];
        _coverView.backgroundColor = [UIColor blackColor];
    }
    return _coverView;
}

- (UIButton *)allCoverButton {
    if (_allCoverButton == nil) {
        _allCoverButton = [[UIButton alloc] initWithFrame:self.bounds];
    }
    return _allCoverButton;
}


@end
