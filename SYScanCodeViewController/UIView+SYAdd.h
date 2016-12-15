//
//  UIView+SYAdd.h
//  SYToolExample
//
//  Created by bcmac3 on 2016/11/15.
//  Copyright © 2016年 ShenYang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface UIView (SYAdd)
/**
 * 返回视图的控制器
 */
#pragma mark - property
@property (nonatomic) CGFloat sy_x;         ///< frame.origin.x
@property (nonatomic) CGFloat sy_y;         ///< frame.origin.y
@property (nonatomic) CGFloat sy_right;     ///< frame.origin.x + frame.size.width
@property (nonatomic) CGFloat sy_bottom;    ///< frame.origin.x + frame.size.height
@property (nonatomic) CGFloat sy_width;     ///< frame.size.width
@property (nonatomic) CGFloat sy_height;    ///< frame.size.height
@property (nonatomic) CGFloat sy_centerX;   ///< center.x
@property (nonatomic) CGFloat sy_centerY;   ///< center.y
@property (nonatomic) CGPoint sy_origin;    ///< frame.origin
@property (nonatomic) CGSize  sy_size;       ///< frame.size

@end
