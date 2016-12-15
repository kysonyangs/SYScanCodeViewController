//
//  SYScanCodeViewController.m
//  
//
//  Created by bcmac3 on 14/12/2016.
//  Copyright © 2016 ShenYang. All rights reserved.
//

#import "SYScanCodeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIView+SYAdd.h"

//以iphone5为基础 坐标都以iphone5为基准 进行代码的适配
#define ratio         [[UIScreen mainScreen] bounds].size.width/320.0

#define kBgImgX             45*ratio
#define kBgImgY             (64+70)*ratio
#define kBgImgWidth         230*ratio

#define kScrollLineHeight   20*ratio

#define kTipY               (kBgImgY+kBgImgWidth+5)
#define kTipHeight          20*ratio

@interface SYScanCodeViewController () <AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> // 用于处理采集信息的代理
@property (nonatomic, strong) AVCaptureSession * session; // 输入输出的中间桥梁

@property (nonatomic, copy) NSString *code;

/// 计时器
@property (strong, nonatomic) CADisplayLink *link;
/// 实际扫描区域
@property (nonatomic, strong) UIImageView *bgImgeView;
/// 有效扫描区域循环往返的一条线(图片)
@property (nonatomic, strong) UIImageView *scrollLine;
/// 线所在位置
@property (nonatomic, assign) BOOL down;

/// 扫码有效区域外提示文字
@property (strong, nonatomic) UILabel *tip;
@property (nonatomic, strong) UIColor *navbarOriginalColor;
@property (nonatomic, strong) UIView *maskView;
@end

@implementation SYScanCodeViewController

- (instancetype)initWithSuccessBlock:(successBlock)successBlock {
    if (self = [super init]) {
        self.successBlock = successBlock;
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.session startRunning];
    // 计时器添加到循环中去
    [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    self.maskView.hidden = YES;
    [self showAllView];
    [self setupNavigationItem];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.session stopRunning];
    self.navigationController.navigationBar.barTintColor = self.navbarOriginalColor;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];
    self.navbarOriginalColor = self.navigationController.navigationBar.barTintColor;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithWhite:0 alpha:0.6];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    NSString *backImage = self.backImageName ? self.backImageName : @"SYScan.bundle/back";
    [button setBackgroundImage:[UIImage imageNamed:backImage] forState:UIControlStateNormal];
    button.frame = CGRectMake(0, 0, 26, 10);
    [button addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    [self setupCamera];

    [self setupView];
    [self hideAllView];
    self.maskView.hidden = NO;
}

- (void)showAllView {
    [UIView animateWithDuration:0.3 animations:^{
        self.bgImgeView.hidden = NO;
        self.bgImgeView.sy_size = CGSizeMake(kBgImgWidth, kBgImgWidth);
        self.bgImgeView.center = CGPointMake(kBgImgX+kBgImgWidth/2, kBgImgY+kBgImgWidth/2);
    } completion:^(BOOL finished) {
        self.tip.hidden = NO;
    }];
}

- (void)hideAllView {
    self.bgImgeView.hidden = YES;
    self.tip.hidden = YES;
}

- (void)setupView {
    _bgImgeView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _bgImgeView.center = CGPointMake(kBgImgX+kBgImgWidth/2, kBgImgY+kBgImgWidth/2);
    NSString *bgImageName = self.bgImageName ? self.bgImageName : @"SYScan.bundle/scanBackground";
    _bgImgeView.image = [UIImage imageNamed:bgImageName];
    _bgImgeView.clipsToBounds = YES;
    [self.view addSubview:_bgImgeView];

    _scrollLine = [[UIImageView alloc] initWithFrame:CGRectMake(0, -20, kBgImgWidth, kScrollLineHeight)];
    NSString *scanLineImageName = self.scanLineImageName ? self.scanLineImageName : @"SYScan.bundle/scanLine";
    _scrollLine.image = [UIImage imageNamed:scanLineImageName];
    [_bgImgeView addSubview:_scrollLine];

    _tip = [[UILabel alloc] initWithFrame:CGRectMake(kBgImgX, kTipY, kBgImgWidth, kTipHeight)];
    _tip.text = self.tipTitle ? self.tipTitle : @"将二维码/条码放入框内，即可自动扫描";
    _tip.numberOfLines = 0;
    _tip.textColor = [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1];
    _tip.textAlignment = NSTextAlignmentCenter;
    _tip.font = [UIFont systemFontOfSize:12 * ratio];
    [self.view addSubview:_tip];

    _link = [CADisplayLink displayLinkWithTarget:self selector:@selector(lineAnimation)];
}

- (void)setupCamera {
    CGFloat screenWidth  =  [[UIScreen mainScreen] bounds].size.width;
    CGFloat screenHeight =  [[UIScreen mainScreen] bounds].size.height;
    // 获取摄像设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    // 创建输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if (!input) return;

    // 创建输出流
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc]init];
    // 设置代理 在主线程里刷新
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    // 设置有效扫描区域[0-1]
    CGRect rect = CGRectMake(kBgImgY/screenHeight, kBgImgX/screenWidth, kBgImgWidth/screenHeight, kBgImgWidth/screenWidth);
    output.rectOfInterest = rect;

    // 创建会话(桥梁)
    _session = [[AVCaptureSession alloc]init];
    // 高质量采集率
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    if ([_session canAddInput:input]) {
        [_session addInput:input];
    }

    if ([_session canAddOutput:output]) {
        [_session addOutput:output];
    }

    // 设置扫码支持的编码格式(如下设置条形码和二维码兼容)
    [output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code]];

    // 创建预览图层
    AVCaptureVideoPreviewLayer *preview = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    preview.frame = self.view.layer.bounds;
    [self.view.layer insertSublayer:preview atIndex:0];

    // 设置中空区域，即有效扫描区域(中间扫描区域透明度比周边要低的效果)
    UIView *maskView = [[UIView alloc] initWithFrame:self.view.bounds];
    maskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.64];
    [self.view addSubview:maskView];
    UIBezierPath *rectPath = [UIBezierPath bezierPathWithRect:self.view.bounds];
    [rectPath appendPath:[[UIBezierPath bezierPathWithRoundedRect:CGRectMake(kBgImgX, kBgImgY, kBgImgWidth, kBgImgWidth) cornerRadius:1] bezierPathByReversingPath]];
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = rectPath.CGPath;
    maskView.layer.mask = shapeLayer;

    // 开始捕获
//    [_session startRunning];
}

- (void)setupNavigationItem {
    self.navigationItem.title = self.navTitle ? self.navTitle : @"";
    if (self.showAlbum) {
        UIBarButtonItem *rightBtn = [[UIBarButtonItem alloc]
                                     initWithTitle:@"相册"
                                     style:UIBarButtonItemStylePlain
                                     target:self
                                     action:@selector(openPhoto)];
        self.navigationItem.rightBarButtonItem = rightBtn;
    }
}

#pragma mark - private Event
- (void)openPhoto {
    //1.判断相册是否可以打开
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        return;
    }
    // 1.停止扫描
    [self.session stopRunning];
    // 2.停止冲击波
    [self.link removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

    //2.创建图片选择控制器
    UIImagePickerController *ipc = [[UIImagePickerController alloc]init];
    ipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    ipc.delegate = self;
    //选中之后大图编辑模式
    ipc.allowsEditing = YES;
    [self presentViewController:ipc animated:YES completion:nil];
}

- (void)lineAnimation {
    if (!_down) {
        CGFloat y = _scrollLine.frame.origin.y;
        y += 2;
        _scrollLine.sy_y = y;
        if (y >= (kBgImgWidth + 20)) {
            _down = YES;
        }
    } else {
        _scrollLine.sy_y = -20;
        _down = NO;

    }
}

- (void)back {
    if (self.successBlock && self.code && self.code.length > 0) {
        self.successBlock(self.code);
    }
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - 提示框
- (void)showAlertWithTitle:(NSString *)title Message:(NSString *)message {
    UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertCtrl addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self.session startRunning];
        [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }]];
    [self presentViewController:alertCtrl animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate
// 相册获取的照片进行处理
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    // 1.取出选中的图片
    UIImage *pickImage = info[UIImagePickerControllerOriginalImage];

    CIImage *ciImage = [CIImage imageWithCGImage:pickImage.CGImage];

    //2.从选中的图片中读取二维码数据
    //2.1创建一个探测器
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];

    // 2.2利用探测器探测数据
    NSArray *feature = [detector featuresInImage:ciImage];

    [picker dismissViewControllerAnimated:YES completion:nil];
    // 2.3取出探测到的数据
    if (feature.count == 0) {
        [self showAlertWithTitle:@"提示" Message:@"没有扫描到有效二维码"];
    }

    for (CIQRCodeFeature *result in feature) {
        NSString *codeString = result.messageString;
        self.code = codeString;
        //二维码信息回传
        if (self.successBlock) {
            [self back];
            return;
        }

        NSString *message = [NSString stringWithFormat:@"扫描结果：%@", codeString];
        [self showAlertWithTitle:@"提示" Message:message];
    }
}

#pragma mark AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    NSString *codeString;
    if ([metadataObjects count] > 0) {
        [self openShake:YES Sound:YES];
        // 1.停止扫描
        [self.session stopRunning];
        // 2.停止冲击波
        [self.link removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects lastObject];
        if (metadataObject) {
            codeString = metadataObject.stringValue;
            self.code = codeString;
            if(_successBlock) {
                [self back];
                return;
            }

            NSString *message = [NSString stringWithFormat:@"扫描结果：%@", codeString];
            [self showAlertWithTitle:@"提示" Message:message];

        }
    } else {
        NSLog(@"无扫描信息");
        return;
    }
}

- (void)openShake:(BOOL)shaked Sound:(BOOL)sounding {
    if (shaked) {
        //开启系统震动
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
    if (sounding) {
        //设置自定义声音
        SystemSoundID soundID;
        NSString *bundleName = [[NSBundle mainBundle] pathForResource:@"SYScan" ofType:@"bundle"];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle bundleWithPath:bundleName] pathForResource:@"ring" ofType:@"wav"]], &soundID);
        AudioServicesPlaySystemSound(soundID);
    }
}

- (UIView *)maskView {
    if (!_maskView) {
        _maskView = [[UIView alloc] initWithFrame:self.view.bounds];
        _maskView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
        [self.view addSubview:_maskView];
        _maskView.hidden = YES;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.text = @"正在加载...";
        [label sizeToFit];
        label.textColor = [UIColor whiteColor];
        label.center = _maskView.center;
        [_maskView addSubview:label];

        UIActivityIndicatorView *act = [[UIActivityIndicatorView alloc] init];
        act.center = _maskView.center;
        CGAffineTransform transform = CGAffineTransformMakeScale(1.5f, 1.5f);
        act.transform = transform;
        label.sy_y = act.sy_bottom + 25;
        [act startAnimating];
        [_maskView addSubview:act];
    }
    [self.view bringSubviewToFront:_maskView];
    return _maskView;
}

@end
