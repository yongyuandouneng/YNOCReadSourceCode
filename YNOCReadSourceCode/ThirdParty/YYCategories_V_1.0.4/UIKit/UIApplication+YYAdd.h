//
//  UIApplication+YYAdd.h
//  YYCategories <https://github.com/ibireme/YYCategories>
//
//  Created by ibireme on 13/4/4.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Provides extensions for `UIApplication`.
 */
@interface UIApplication (YYAdd)

/// "Documents" folder in this app's sandbox.
@property (nonatomic, readonly) NSURL *documentsURL; /// 取得文档URL
@property (nonatomic, readonly) NSString *documentsPath; /// 取得文档路径

/// "Caches" folder in this app's sandbox.
@property (nonatomic, readonly) NSURL *cachesURL; /// 取得Cache URL
@property (nonatomic, readonly) NSString *cachesPath; /// 取得CachePath

/// "Library" folder in this app's sandbox.
@property (nonatomic, readonly) NSURL *libraryURL; /// 取得library URL
@property (nonatomic, readonly) NSString *libraryPath; /// 取得library Path

/// Application's Bundle Name (show in SpringBoard).
@property (nullable, nonatomic, readonly) NSString *appBundleName; /// app 昵称

/// Application's Bundle ID.  e.g. "com.ibireme.MyApp"
@property (nullable, nonatomic, readonly) NSString *appBundleID; /// 包名

/// Application's Version.  e.g. "1.2.0"
@property (nullable, nonatomic, readonly) NSString *appVersion; /// 版本号

/// Application's Build number. e.g. "123"
@property (nullable, nonatomic, readonly) NSString *appBuildVersion; /// build版本号

/// Whether this app is priated (not install from appstore).
@property (nonatomic, readonly) BOOL isPirated; ///

/// Whether this app is being debugged (debugger attached).
@property (nonatomic, readonly) BOOL isBeingDebugged;

/// Current thread real memory used in byte. (-1 when error occurs)
@property (nonatomic, readonly) int64_t memoryUsage; /// 内存使用量

/// Current thread CPU usage, 1.0 means 100%. (-1 when error occurs)
@property (nonatomic, readonly) float cpuUsage; ///  cpu 使用量


/**
 Increments the number of active network requests.
 If this number was zero before incrementing, this will start animating the 
 status bar network activity indicator.
 
 This method is thread safe.
 */
- (void)incrementNetworkActivityCount;

/**
 Decrements the number of active network requests. 
 If this number becomes zero after decrementing, this will stop animating the 
 status bar network activity indicator.
 
 This method is thread safe.
 */
- (void)decrementNetworkActivityCount;


/// Returns YES in App Extension.
+ (BOOL)isAppExtension;

/// Same as sharedApplication, but returns nil in App Extension.
+ (nullable UIApplication *)sharedExtensionApplication;

@end

NS_ASSUME_NONNULL_END
