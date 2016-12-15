//
//  ViewController.m
//  SYScanCodeViewControllerExample
//
//  Created by bcmac3 on 15/12/2016.
//  Copyright © 2016 ShenYang. All rights reserved.
//

#import "ViewController.h"
#import "SYScanCodeViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)scanEvent:(id)sender {
    SYScanCodeViewController *scan = [[SYScanCodeViewController alloc] initWithSuccessBlock:^(NSString *codeInfo) {
        NSLog(@"%@", codeInfo);
    }];
    scan.showAlbum = YES;
    scan.navTitle = @"扫一扫";
    [self.navigationController pushViewController:scan animated:YES];
}


@end
