//
//  RACReplaySubject.h
//  ReactiveObjC
//
//  Created by Josh Abernathy on 3/14/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "RACSubject.h"

NS_ASSUME_NONNULL_BEGIN

extern const NSUInteger RACReplaySubjectUnlimitedCapacity;

/// A replay subject saves the values it is sent (up to its defined capacity)
/// and resends those to new subscribers. It will also replay an error or
/// completion.
/*
 // 可以先订阅信号，也可以先发送信号。
 // 只要订阅了信号，那么发送信号时所有的都会收到信号
 */
@interface RACReplaySubject<ValueType> : RACSubject<ValueType>

/// Creates a new replay subject with the given capacity. A capacity of
/// RACReplaySubjectUnlimitedCapacity means values are never trimmed.
+ (instancetype)replaySubjectWithCapacity:(NSUInteger)capacity;

@end

NS_ASSUME_NONNULL_END
