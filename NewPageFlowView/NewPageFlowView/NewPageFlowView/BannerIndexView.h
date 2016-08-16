//
//  BannerIndexView.h
//  NewPageFlowView
//
//  Created by MrJalen on 16/8/4.
//  Copyright © 2016年 lianjiang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BannerIndexView : UIView


/** 主图 */
@property (nonatomic, strong) UIImageView *mainImageView;

/** 用来变色的view */
@property (nonatomic, strong) UIView *coverView;

/** 覆盖button */
@property (nonatomic, strong) UIButton *allCoverButton;


@end
