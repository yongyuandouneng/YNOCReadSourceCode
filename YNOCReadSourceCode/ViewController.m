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
#import "ReactiveObjC.h"
@interface ViewController ()


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   

    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [subscriber sendNext:@"2"];
//        });
//        return nil;
//    }];
//
//    [signal subscribeNext:^(id  _Nullable x) {
//        NSLog(@"1");
//    }];
//
//    [signal subscribeNext:^(id  _Nullable x) {
//        NSLog(@"2");
//    }];

    RACSubject *subject = [RACSubject subject];
    [subject subscribeNext:^(id  _Nullable x) {
        NSLog(@"------");
    }];
    [subject subscribeNext:^(id  _Nullable x) {
        NSLog(@"======");
    }];
    [subject sendNext:@"1"];
    [subject sendNext:@"3"];
    [subject subscribeNext:^(id  _Nullable x) {
        NSLog(@"~~~~~");
    }];
    
}

@end
