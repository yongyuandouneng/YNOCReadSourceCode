//
//  YYDispatchQueueManager.h
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 15/7/18.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

#if __has_include(<YYDispatchQueuePool/YYDispatchQueuePool.h>)
FOUNDATION_EXPORT double YYDispatchQueuePoolVersionNumber;
FOUNDATION_EXPORT const unsigned char YYDispatchQueuePoolVersionString[];
#endif

#ifndef YYDispatchQueuePool_h
#define YYDispatchQueuePool_h

NS_ASSUME_NONNULL_BEGIN

/**
 A dispatch queue pool holds multiple serial queues.
 拥有多个串行队列调度队列池。
 Use this class to control queue's thread count (instead of concurrent queue).
 使用这个类来控制队列的线程数量(而不是并发队列)。
 */
@interface YYDispatchQueuePool : NSObject
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

/**
 根据昵称、线程池大小、品质创建线程池
 Creates and returns a dispatch queue pool.
 @param name       The name of the pool.
 @param queueCount Maxmium queue count, should in range (1, 32).
 @param qos        Queue quality of service (QOS).
 @return A new pool, or nil if an error occurs.
 */
- (instancetype)initWithName:(nullable NSString *)name queueCount:(NSUInteger)queueCount qos:(NSQualityOfService)qos;

/// Pool's name.
/// 池的昵称
@property (nullable, nonatomic, readonly) NSString *name;

/// Get a serial queue from pool.
/// 从池中取得一个同步队列
- (dispatch_queue_t)queue;

/// 返回默认线程池
+ (instancetype)defaultPoolForQOS:(NSQualityOfService)qos;

@end

/// Get a serial queue from global queue pool with a specified qos.
/// 从全局的串行队列中取得队列
extern dispatch_queue_t YYDispatchQueueGetForQOS(NSQualityOfService qos);

NS_ASSUME_NONNULL_END

#endif
