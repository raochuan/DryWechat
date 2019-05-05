//
//  DryWechatMedia.m
//  DryWechatKit
//
//  Created by Dry on 2018/8/14.
//  Copyright © 2018 Dry. All rights reserved.
//

#import "DryWechatMedia.h"

@implementation DryWechatMedia

#pragma mark - 构造
- (instancetype)init {
    
    self = [super init];
    if (self) {
        
        /// 非空属性初始化
        self.title = @"";
        self.descrip = @"";
        self.webpageUrl = @"";
    }
    
    return self;
}

#pragma mark - 析构
- (void)dealloc {
    
    /// 打印销毁
    NSLog(@"已释放: %@", NSStringFromClass(self.class));
}

@end


