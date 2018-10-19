//
//  PLeakSniffer.h
//  PLeakSniffer
//
//  Created by gao feng on 16/7/1.
//  Copyright © 2016年 music4kid. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PLeakLog(format, ...) NSLog(format, ##__VA_ARGS__)

#define Notif_PLeakSniffer_Ping @"Notif_PLeakSniffer_Ping"
#define Notif_PLeakSniffer_Pong @"Notif_PLeakSniffer_Pong"
/// 协议 sniffer
@protocol PLeakSnifferCitizen <NSObject>

+ (void)prepareForSniffer;
/// 标记存活
- (BOOL)markAlive;
/// 返回是否存活
- (BOOL)isAlive;

@end

@interface PLeakSniffer : NSObject

+ (instancetype)sharedInstance;

- (void)installLeakSniffer;
- (void)addIgnoreList:(NSArray*)ignoreList;
- (void)alertLeaks; //use UIAlertView to notify leaks

@end
