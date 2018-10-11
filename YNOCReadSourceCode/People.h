//
//  People.h
//  YNOCReadSourceCode
//
//  Created by ZYN on 2018/9/29.
//  Copyright © 2018 cn.yn.oc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PeopleSub : NSObject

@property (nonatomic, copy) NSString *name;

@end

@interface People : NSObject

@property (nonatomic, copy) NSArray<PeopleSub *> *list;

@end


