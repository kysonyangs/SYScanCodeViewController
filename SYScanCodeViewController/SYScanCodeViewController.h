//
//  SYScanCodeViewController.h
//
//
//  Created by bcmac3 on 14/12/2016.
//  Copyright © 2016 ShenYang. All rights reserved.
//
/*
 由于要使用相册+相机权限，所以请先在info.plist 配置以下参数
 Privacy - Photo Library Usage Description  Or  NSPhotoLibraryUsageDescription
 Privacy - Camera Usage Description Or  NSCameraUsageDescription
 */

#import <UIKit/UIKit.h>

typedef void(^successBlock)(NSString *codeInfo);

@interface SYScanCodeViewController : UIViewController
/// 扫码成功回调
@property (nonatomic, copy) successBlock successBlock;

/// 导航栏标题
@property (nonatomic, copy) NSString *navTitle;

/// 是否显示相册按钮
@property (nonatomic, assign) BOOL showAlbum;

/// 返回按钮图片
@property (nonatomic, copy) NSString *backImageName;

/// 矩形框图片
@property (nonatomic, copy) NSString *bgImageName;

/// 扫描线图片
@property (nonatomic, copy) NSString *scanLineImageName;

/// 提示信息
@property (nonatomic, copy) NSString *tipTitle;


/// 快速初始化
- (instancetype)initWithSuccessBlock:(successBlock)successBlock;

@end
