//
//  RACDynamicSignal.h
//  ReactiveObjC
//
//  Created by Justin Spahr-Summers on 2013-10-10.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "RACSignal.h"

// A private `RACSignal` subclasses that implements its subscription behavior
// using a block.
@interface RACDynamicSignal : RACSignal
/*
* 1.创建信号，首先把didSubscribe保存到信号中，还不会触发。
* 2.当信号被订阅，也就是调用signal的subscribeNext:nextBlock
2.1 subscribeNext内部会创建订阅者subscriber，并且把nextBlock保存到subscriber中。
2.2 subscribeNext内部会调用siganl的didSubscribe
* 3.siganl的didSubscribe中调用[subscriber sendNext:@1];
* 3.1 sendNext底层其实就是执行subscriber的nextBlock
 */
+ (RACSignal *)createSignal:(RACDisposable * (^)(id<RACSubscriber> subscriber))didSubscribe;

@end
