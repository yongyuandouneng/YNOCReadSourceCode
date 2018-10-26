//
//  ViewController.m
//  YNOCReadSourceCode
//
//  Created by ZYN on 2018/4/16.
//  Copyright © 2018年 cn.yn.oc. All rights reserved.
//

#import "ViewController.h"
#import "YYCache.h"
#import "YYModel.h"
#import "People.h"
#import "Typeset.h"

@interface ViewController ()

@property (nonatomic, strong) UILabel *label;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _label = [[UILabel alloc] initWithFrame:CGRectMake(100, 100, 300, 300)];
    _label.numberOfLines = 0;
    NSString *a = nil;
    _label.attributedText = a.typeset.color([UIColor redColor]).string;
    
    [self.view addSubview:_label];
    
}

@end
