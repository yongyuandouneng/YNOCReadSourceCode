//
//  RACSubject.h
//  ReactiveObjC
//
//  Created by Josh Abernathy on 3/9/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "RACSignal.h"
#import "RACSubscriber.h"

NS_ASSUME_NONNULL_BEGIN

/// A subject can be thought of as a signal that you can manually control by
/// sending next, completed, and error.
///
/// They're most helpful in bridging the non-RAC world to RAC, since they let you
/// manually control the sending of events.
/*
    遵守RACSubscribe协议，就既能发送，又能订阅信号,
    RACSubject订阅信号的实质就是将内部创建的订阅者保存在订阅者数组self.subscribers中,
    等待sendNext后进行调用.
    不能够先sendNext:
 */
@interface RACSubject<ValueType> : RACSignal<ValueType> <RACSubscriber>

/// Returns a new subject.
+ (instancetype)subject;

// Redeclaration of the RACSubscriber method. Made in order to specify a generic type.
- (void)sendNext:(nullable ValueType)value;

@end

NS_ASSUME_NONNULL_END
