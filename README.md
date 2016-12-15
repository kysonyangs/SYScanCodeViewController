# SYScanCodeViewController
扫描条形码/二维码
感兴趣的给个Star吧...

# CocoaPods:
```
pod 'SYScanCodeViewController', '~> 0.0.4'
```

# Usage:
导入头文件
```
#import "SYScanCodeViewController.h"
```

```
SYScanCodeViewController *scan = [[SYScanCodeViewController alloc] initWithSuccessBlock:^(NSString *codeInfo) {
    NSLog(@"%@", codeInfo);
}];
```
可以选择相册
```
scan.showAlbum = YES;
```
标题
```
scan.navTitle = @"扫一扫";
```
提示文字
```
scan.tipTitle = @"将二维码/条码放入框内，即可自动扫描";
```
返回按钮图片名称
```
scan.backImageName = @"back";
```

# 效果图
![](http://7xsuaf.com1.z0.glb.clouddn.com/ThreePart/City.gif)


# iteration:
0.0.2 - 发布第一个版本,读取相册不支持条形码，只支持二维码，测试只发现微信可以，支付宝不行...

# Other: 
使用中有任何问题，请将问题发送给我，谢谢大家帮忙完善!
Email: kellenyang@163.com
