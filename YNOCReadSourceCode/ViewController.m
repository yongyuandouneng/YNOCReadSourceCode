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

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    People *p = [People yy_modelWithDictionary:@{@"list" : @[@{@"name" : @"1"}, @{@"name" : @"2"}]}];
    
    NSLog(@"1");
}

@end
