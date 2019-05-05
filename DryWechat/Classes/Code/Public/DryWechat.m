//
//  DryWechat.m
//  DryWechatKit
//
//  Created by Dry on 2018/8/14.
//  Copyright © 2018 Dry. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "DryWechat.h"
#import "WXApi.h"

#pragma mark - 静态常量(微信授权类型)
static NSString *const kAuthScope   = @"snsapi_message,snsapi_userinfo,snsapi_friend,snsapi_contact";

#pragma mark - 单例常量
static DryWechat *theInstance = nil;

#pragma mark - DryWechat
@interface DryWechat() <WXApiDelegate>

@property (nonatomic, readwrite, assign) BOOL isRegisterSDK;//SDK是否注册成功

/// 信开放平台下发数据
@property (nonatomic, readwrite, nullable, copy) NSString *appID;//微信开放平台下发的账号
@property (nonatomic, readwrite, nullable, copy) NSString *secret;//微信开放平台下发的账号密钥
@property (nonatomic, readwrite, nullable, copy) NSString *partnerID;//商家向财付通申请的商家id
@property (nonatomic, readwrite, nullable, copy) NSString *package;//商家根据财付通文档填写的数据和签名
@property (nonatomic, readwrite, nullable, copy) NSString *partnerKey;//商户密钥

/// 回调Block
@property (nonatomic, readwrite, nullable, copy) BlockDryWechatAuth             authBlock;//授权回调
@property (nonatomic, readwrite, nullable, copy) BlockDryWechatStatusCode       statusCodeBlock;//状态码回调
@property (nonatomic, readwrite, nullable, copy) BlockDryWechatShareMiniProgram ShareMiniProgramBlock;//分享小程序回调

@end

@implementation DryWechat

#pragma mark - 单例
+ (instancetype)sharedInstance {
    
    if (!theInstance) {
        
        static dispatch_once_t oncePredicate;
        dispatch_once(&oncePredicate, ^{
            
            theInstance = [[DryWechat alloc] init];
        });
    }
    
    return theInstance;
}

#pragma mark - 构造
- (instancetype)init {
    
    self = [super init];
    if (self) {
        
        /// 数据初始化
        self.isRegisterSDK = NO;
        
        /// 数据初始化(信开放平台下发数据)
        self.appID = nil;
        self.secret = nil;
        self.partnerID = nil;
        self.package = nil;
        self.partnerKey = nil;
        
        /// 数据初始化(回调Block)
        self.authBlock = nil;
        self.statusCodeBlock = nil;
        self.ShareMiniProgramBlock = nil;
    }
    
    return self;
}

#pragma mark - 析构
- (void)dealloc {
    
    /// 打印销毁
    NSLog(@"已销毁: %@", NSStringFromClass(self.class));
    
    /// 释放属性(信开放平台下发数据)
    self.appID = nil;
    self.secret = nil;
    self.partnerID = nil;
    self.package = nil;
    self.partnerKey = nil;
    
    /// 释放属性(回调Block)
    self.authBlock = nil;
    self.statusCodeBlock = nil;
    self.ShareMiniProgramBlock = nil;
}

#pragma mark - 客户端配置
/** 注册微信客户端 */
+ (BOOL)registerWithAppID:(nonnull NSString *)appID
                   secret:(nonnull NSString *)secret
                partnerID:(nullable NSString *)partnerID
               partnerKey:(nullable NSString *)partnerKey
                  package:(nullable NSString *)package {
    
    /// 数据源检查
    if (!appID || !secret) {
        return NO;
    }
    
    /// 注册
    BOOL success = [WXApi registerApp:appID];
    
    /// 保存数据
    if (success) {
        [DryWechat sharedInstance].isRegisterSDK = YES;
        [DryWechat sharedInstance].appID = appID;
        [DryWechat sharedInstance].secret = secret;
        [DryWechat sharedInstance].partnerID = partnerID;
        [DryWechat sharedInstance].package = package;
        [DryWechat sharedInstance].partnerKey = partnerKey;
    }else {
        [DryWechat sharedInstance].isRegisterSDK = NO;
        [DryWechat sharedInstance].appID = nil;
        [DryWechat sharedInstance].secret = nil;
        [DryWechat sharedInstance].partnerID = nil;
        [DryWechat sharedInstance].package = nil;
        [DryWechat sharedInstance].partnerKey = nil;
    }
    
    return success;
}

/** 处理微信通过URL启动App时传递的数据 */
+ (BOOL)handleOpenURL:(nonnull NSURL *)url {
    
    if (url) {
        return [WXApi handleOpenURL:url delegate:[DryWechat sharedInstance]];
    }else {
        return NO;
    }
}

/** 微信客户端是否安装 */
+ (BOOL)isWXAppInstalled {

    return [WXApi isWXAppInstalled];
}

/** 微信客户端是否支持OpenApi */
+ (BOOL)isWXAppSupportApi {
    
    return [WXApi isWXAppSupportApi];
}

#pragma mark - 申请授权(获取: OpenID、接口凭证)
+ (void)applyAuth:(nonnull BlockDryWechatAuth)completion {
    
    /// 检查数据
    if (!completion) {
        return;
    }
    
    /// 检查(SDK是否注册)
    if (![DryWechat sharedInstance].isRegisterSDK) {
        completion(kDryWechatStatusCodeNoRegister, nil, nil);
        return;
    }
    
    /// 检查(客户端是否安装)
    if (![DryWechat isWXAppInstalled]) {
        completion(kDryWechatStatusCodeNotInstall, nil, nil);
        return;
    }
    
    /// 检查(客户端是否支持)
    if (![DryWechat isWXAppSupportApi]) {
        completion(kDryWechatStatusCodeUnsupport, nil, nil);
        return;
    }
    
    /// 检查(必要参数)
    if (![DryWechat sharedInstance].appID || ![DryWechat sharedInstance].secret) {
        completion(kDryWechatStatusCodeParamsError, nil, nil);
        return;
    }
    
    /// 更新Block
    [DryWechat sharedInstance].authBlock = completion;
    
    /// 发送Auth请求到微信
    SendAuthReq *authReq = [[SendAuthReq alloc] init];
    authReq.scope = kAuthScope;
    authReq.state = [[NSBundle mainBundle] bundleIdentifier];
    authReq.openID = [DryWechat sharedInstance].appID;
    [WXApi sendAuthReq:authReq viewController:nil delegate:[DryWechat sharedInstance]];
}

#pragma mark - 获取微信的用户信息(昵称、头像地址)
+ (void)userInfoWithOpenID:(nonnull NSString *)openID
               accessToken:(nonnull NSString *)accessToken
                completion:(nonnull BlockDryWechatUserInfo)completion {
    
    /// 检查数据
    if (!completion) {
        return;
    }
    
    /// 检查(必要参数)
    if (!openID || !accessToken) {
        completion(kDryWechatStatusCodeParamsError, nil, nil);
        return;
    }
    
    /// 请求用户信息
    NSString *host = @"https://api.weixin.qq.com/sns/userinfo";
    NSString *url = [NSString stringWithFormat:@"%@?access_token=%@&openid=%@", host, accessToken, openID];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        
        /// 获取数据失败
        if (!data || connectionError) {
            completion(kDryWechatStatusCodeUnknown, nil, nil);
            return ;
        }
        
        /// 原始数据检查
        id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers | NSJSONReadingAllowFragments error:nil];
        if (!json || ![json isKindOfClass:[NSDictionary class]]) {
            completion(kDryWechatStatusCodeUnknown, nil, nil);
            return;
        }
        
        /// 转换数据
        NSDictionary *dict = (NSDictionary *)json;
        NSString *nickName = nil;
        NSString *headImgURL = nil;
        if ([[dict allKeys] containsObject:@"nickname"]) {
            nickName = [NSString stringWithFormat:@"%@", [dict valueForKey:@"nickname"]];
        }
        if ([[dict allKeys] containsObject:@"headimgurl"]) {
            headImgURL = [NSString stringWithFormat:@"%@", [dict valueForKey:@"headimgurl"]];
        }
        
        /// 返回数据
        completion(kDryWechatStatusCodeSuccess, nickName, headImgURL);
    }];
}

#pragma mark - 支付
/** 将字符串转换成MD5 */
+ (nonnull NSString *)md5FromString:(nonnull NSString *)aString {
    
    /// 转换数据
    const char *cStr = [aString UTF8String];
    
    /// 加密规则
    unsigned char result[16]= "0123456789abcdef";
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    
    /// 这里的x是小写则产生的md5也是小写，x是大写则md5是大写，这里只能用大写
    return [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]];
}

/**
 * @函数说明    创建发起支付时的签名(sign)
 * @输入参数    appID:      微信开放平台下发的账号
 * @输入参数    partnerID:  商家向财付通申请的商家id
 * @输入参数    partnerKey: 商户密钥
 * @输入参数    package:    商家根据财付通文档填写的数据和签名
 * @输入参数    prepayID:   预支付订单号(服务端下发)
 * @输入参数    noncestr:   随机串(服务端下发)
 * @输入参数    timestamp:  当前时间戳
 * @返回数据    NSString
 */
+ (nullable NSString *)signWithAppID:(nonnull NSString *)appID
                           partnerID:(nonnull NSString *)partnerID
                          partnerKey:(nonnull NSString *)partnerKey
                             package:(nonnull NSString *)package
                            prepayID:(nonnull NSString *)prepayID
                            noncestr:(nonnull NSString *)noncestr
                           timestamp:(UInt32)timestamp {
    
    /// 检查数据
    if (!appID || !partnerID || !partnerKey || !package || !prepayID || !noncestr) {
        return nil;
    }
    
    /// 创建签名参数
    NSMutableDictionary *signParamsDict = [NSMutableDictionary dictionary];
    [signParamsDict setValue:appID forKey:@"appid"];
    [signParamsDict setValue:partnerID forKey:@"partnerid"];
    [signParamsDict setValue:prepayID forKey:@"prepayid"];
    [signParamsDict setValue:package forKey:@"package"];
    [signParamsDict setValue:noncestr forKey:@"noncestr"];
    [signParamsDict setValue:[NSString stringWithFormat:@"%u", (unsigned int)timestamp] forKey:@"timestamp"];
    
    /// 将签名参数的key按照字母顺序排列
    NSArray *keyArray = [signParamsDict allKeys];
    NSArray *sortArray = [keyArray sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];
    }];
    
    /// 将签名参数的key按照字母顺序排列，拼接对应的值，创建“商户密钥”
    NSMutableString *contentStr = [NSMutableString string];
    for (NSString *key in sortArray) {
        
        if (![[signParamsDict valueForKey:key] isEqualToString:@""]
            && ![[signParamsDict valueForKey:key] isEqualToString:@"sign"]
            && ![[signParamsDict valueForKey:key] isEqualToString:@"key"]) {
            
            [contentStr appendFormat:@"%@=%@&", key, [signParamsDict valueForKey:key]];
        }
    }
    
    /// 添加“商户密钥”key字段
    [contentStr appendFormat:@"key=%@", partnerKey];
    
    /// 将“商户密钥”MD5处理
    NSString *result = [DryWechat md5FromString:contentStr];
    
    return result;
}

/** 支付(调起微信客户端支付，不支持网页) */
+ (void)payWithPrepayID:(nonnull NSString *)prepayID
               noncestr:(nonnull NSString *)noncestr
             completion:(nonnull BlockDryWechatStatusCode)completion {
    
    /// 检查数据
    if (!completion) {
        return;
    }
    
    /// 检查(SDK是否注册)
    if (![DryWechat sharedInstance].isRegisterSDK) {
        completion(kDryWechatStatusCodeNoRegister);
        return;
    }
    
    /// 检查(客户端是否安装)
    if (![DryWechat isWXAppInstalled]) {
        completion(kDryWechatStatusCodeNotInstall);
        return;
    }
    
    /// 检查(客户端是否支持)
    if (![DryWechat isWXAppSupportApi]) {
        completion(kDryWechatStatusCodeUnsupport);
        return;
    }
    
    /// 检查(必要参数)
    if (![DryWechat sharedInstance].appID
        || ![DryWechat sharedInstance].secret
        || ![DryWechat sharedInstance].partnerID
        || ![DryWechat sharedInstance].package
        || ![DryWechat sharedInstance].partnerKey) {
        completion(kDryWechatStatusCodeParamsError);
        return;
    }
    
    /// 检查(支付参数)
    if (!prepayID || !noncestr) {
        completion(kDryWechatStatusCodeParamsError);
        return;
    }
    
    /// 更新Block
    [DryWechat sharedInstance].statusCodeBlock = completion;
    
    /// 时间戳
    NSDate *date = [NSDate date];
    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[date timeIntervalSince1970]];
    UInt32 timeStamp = [timeSp intValue];
    
    /// 签名
    NSString *sign = [DryWechat signWithAppID:[DryWechat sharedInstance].appID
                                    partnerID:[DryWechat sharedInstance].partnerID
                                   partnerKey:[DryWechat sharedInstance].partnerKey
                                      package:[DryWechat sharedInstance].package
                                     prepayID:prepayID
                                     noncestr:noncestr
                                    timestamp:timeStamp];
    
    /// 检查(签名)
    if (!sign) {
        completion(kDryWechatStatusCodeParamsError);
        return;
    }
    
    /// 创建支付请求
    PayReq *req = [[PayReq alloc] init];
    req.partnerId = [DryWechat sharedInstance].partnerID;
    req.package = [DryWechat sharedInstance].package;
    req.prepayId = prepayID;
    req.nonceStr = noncestr;
    req.timeStamp= timeStamp;
    req.sign = sign;
    
    /// 发起支付请求
    [WXApi sendReq:req];
}

#pragma mark - 分享文本信息
+ (void)shareTextWithContent:(nonnull NSString *)content
                       scene:(DryWechatScene)scene
                  completion:(nonnull BlockDryWechatStatusCode)completion {
    
    /// 检查数据
    if (!completion) {
        return;
    }
    
    /// 检查(SDK是否注册)
    if (![DryWechat sharedInstance].isRegisterSDK) {
        completion(kDryWechatStatusCodeNoRegister);
        return;
    }
    
    /// 检查(客户端是否安装)
    if (![DryWechat isWXAppInstalled]) {
        completion(kDryWechatStatusCodeNotInstall);
        return;
    }
    
    /// 检查(客户端是否支持)
    if (![DryWechat isWXAppSupportApi]) {
        completion(kDryWechatStatusCodeUnsupport);
        return;
    }
    
    /// 检查(分享参数)
    if (!content) {
        completion(kDryWechatStatusCodeParamsError);
        return;
    }
    
    /// 更新Block
    [DryWechat sharedInstance].statusCodeBlock = completion;
    
    /// 分享文本信息 */
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.bText = YES;
    req.text = content;
    if (scene == kDryWechatScenePerson) {
        req.scene = WXSceneSession;
    }else if (scene == kDryWechatSceneTimeline) {
        req.scene = WXSceneTimeline;
    }else {
        req.scene = WXSceneFavorite;
    }
    [WXApi sendReq:req];
}

#pragma mark - 分享多媒体信息
+ (void)shareMediaWithType:(DryWechatMediaType)type
                     media:(nonnull DryWechatMedia *)media
                     scene:(DryWechatScene)scene
                completion:(nonnull BlockDryWechatStatusCode)completion {
    
    /// 检查(参数)
    if (!completion) {
        return;
    }
    
    /// 检查(SDK是否注册)
    if (![DryWechat sharedInstance].isRegisterSDK) {
        completion(kDryWechatStatusCodeNoRegister);
        return;
    }
    
    /// 检查(客户端是否安装)
    if (![DryWechat isWXAppInstalled]) {
        completion(kDryWechatStatusCodeNotInstall);
        return;
    }
    
    /// 检查(客户端是否支持)
    if (![DryWechat isWXAppSupportApi]) {
        completion(kDryWechatStatusCodeUnsupport);
        return;
    }
    
    /// 检查(分享参数)
    if (!media) {
        completion(kDryWechatStatusCodeParamsError);
        return;
    }
    
    /// 更新Block
    [DryWechat sharedInstance].statusCodeBlock = completion;
    
    /// 创建分享请求 */
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    if (scene == kDryWechatScenePerson) {
        req.scene = WXSceneSession;
    }else if (scene == kDryWechatSceneTimeline) {
        req.scene = WXSceneTimeline;
    }else {
        req.scene = WXSceneFavorite;
    }
    
    /// 设置多媒体数据 */
    WXMediaMessage *targetMessage = [WXMediaMessage message];
    
    /// 配置通用数据 */
    if (media.title) {
        targetMessage.title = media.title;
    }
    if (media.descrip) {
        targetMessage.description = media.descrip;
    }
    if (media.thumbImage) {
        [targetMessage setThumbImage:media.thumbImage];
    }
    
    /// 根据多媒体类型配置数据
    if (type == kDryWechatMediaTypeImage) {
        
        /// 图片
        WXImageObject *mediaObject = [WXImageObject object];
        if (media.imageData) {
            mediaObject.imageData = media.imageData;
        }
        targetMessage.mediaObject = mediaObject;
        
    }else if (type == kDryWechatMediaTypeMusic) {
        
        /// 音乐
        WXMusicObject *mediaObject = [WXMusicObject object];
        if (media.musicUrl) {
            mediaObject.musicUrl = media.musicUrl;
        }
        if (media.musicLowBandUrl) {
            mediaObject.musicLowBandUrl = media.musicLowBandUrl;
        }
        if (media.musicDataUrl) {
            mediaObject.musicDataUrl = media.musicDataUrl;
        }
        if (media.musicLowBandDataUrl) {
            mediaObject.musicLowBandDataUrl = media.musicLowBandDataUrl;
        }
        targetMessage.mediaObject = mediaObject;
        
    }else if (type == kDryWechatMediaTypeVideo) {
        
        /// 视频
        WXVideoObject *mediaObject = [WXVideoObject object];
        if (media.videoUrl) {
            mediaObject.videoUrl = media.videoUrl;
        }
        if (media.videoLowBandUrl) {
            mediaObject.videoLowBandUrl = media.videoLowBandUrl;
        }
        targetMessage.mediaObject = mediaObject;
        
    }else if (type == kDryWechatMediaTypeWebpage) {
        
        /// 网页
        WXWebpageObject *mediaObject = [WXWebpageObject object];
        if (media.webpageUrl) {
            mediaObject.webpageUrl = media.webpageUrl;
        }
        targetMessage.mediaObject = mediaObject;
        
    }else if (type == kDryWechatMediaTypeAppExtend) {
        
        /// App扩展
        WXAppExtendObject *mediaObject = [WXAppExtendObject object];
        if (media.url) {
            mediaObject.url = media.url;
        }
        if (media.extInfo) {
            mediaObject.extInfo = media.extInfo;
        }
        if (media.fileData) {
            mediaObject.fileData = media.fileData;
        }
        targetMessage.mediaObject = mediaObject;
        
    }else if (type == kDryWechatMediaTypeEmoticon) {
        
        /// 表情
        WXEmoticonObject *mediaObject = [WXEmoticonObject object];
        if (media.emoticonData) {
            mediaObject.emoticonData = media.emoticonData;
        }
        targetMessage.mediaObject = mediaObject;
        
    }else if (type == kDryWechatMediaTypeFile) {
        
        /// 文件
        WXFileObject *mediaObject = [WXFileObject object];
        if (media.tfileExtension) {
            mediaObject.fileExtension = media.tfileExtension;
        }
        if (media.tfileData) {
            mediaObject.fileData = media.tfileData;
        }
        targetMessage.mediaObject = mediaObject;
        
    }else if (type == kDryWechatMediaTypeLocation) {
        
        /// 地理位置
        WXLocationObject *mediaObject = [WXLocationObject object];
        if (media.lng) {
            mediaObject.lng = [media.lng doubleValue];
        }
        if (media.lat) {
            mediaObject.lat = [media.lat doubleValue];
        }
        targetMessage.mediaObject = mediaObject;
        
    }else if (type == kDryWechatMediaTypeText) {
        
        /// 文本
        WXTextObject *mediaObject = [WXTextObject object];
        if (media.contentText) {
            mediaObject.contentText = media.contentText;
        }
        targetMessage.mediaObject = mediaObject;
    }
    
    req.message = targetMessage;
    
    /// 分享多媒体信息
    [WXApi sendReq:req];
}

#pragma mark - 打开微信小程序
+ (void)shareMiniWithUserName:(nonnull NSString *)userName
                         path:(nullable NSString *)path
                         type:(DryWechatMiniProgramType)type
                   completion:(nonnull BlockDryWechatShareMiniProgram)completion {
    
    /// 检查(参数)
    if (!completion) {
        return;
    }
    
    /// 检查(SDK是否注册)
    if (![DryWechat sharedInstance].isRegisterSDK) {
        completion(kDryWechatStatusCodeNoRegister, nil);
        return;
    }
    
    /// 检查(客户端是否安装)
    if (![DryWechat isWXAppInstalled]) {
        completion(kDryWechatStatusCodeNotInstall, nil);
        return;
    }
    
    /// 检查(客户端是否支持)
    if (![DryWechat isWXAppSupportApi]) {
        completion(kDryWechatStatusCodeUnsupport, nil);
        return;
    }
    
    /// 检查(参数)
    if (!userName) {
        completion(kDryWechatStatusCodeParamsError, nil);
        return;
    }
    
    /// 更新Block
    [DryWechat sharedInstance].ShareMiniProgramBlock = completion;
    
    /// 发送请求
    WXLaunchMiniProgramReq *launchMiniProgramReq = [WXLaunchMiniProgramReq object];
    launchMiniProgramReq.userName = userName;
    if (path) {
        launchMiniProgramReq.path = path;
    }
    switch (type) {
        case kDryWechatMiniProgramTypeTest:{
            launchMiniProgramReq.miniProgramType = WXMiniProgramTypeTest;
        }break;
        case kDryWechatMiniProgramTypePreview:{
            launchMiniProgramReq.miniProgramType = WXMiniProgramTypePreview;
        }break;
        default:{
            launchMiniProgramReq.miniProgramType = WXMiniProgramTypeRelease;
        }break;
    }
    [WXApi sendReq:launchMiniProgramReq];
}

#pragma mark - 微信回调(WXApiDelegate)
- (void)onResp:(BaseResp *)resp {
    
    /// 检查(参数)
    if (!resp) {
        return;
    }
    
    /// 授权回调
    if ([resp isKindOfClass:[SendAuthResp class]]) {
        [DryWechat authCallbackWithResp:(SendAuthResp *)resp];
    }
    
    /// 支付回调
    if ([resp isKindOfClass:[PayResp class]]) {
        [DryWechat payCallbackWithResp:(PayResp *)resp];
    }
    
    /// 分享回调
    if ([resp isKindOfClass:[SendMessageToWXResp class]]) {
        [DryWechat shareCallbackWithResp:(SendMessageToWXResp *)resp];
    }
    
    /// 分享微信小程序回调
    if ([resp isKindOfClass:[WXLaunchMiniProgramResp class]]) {
        [DryWechat shareMiniProgramCallbackWithResp:(WXLaunchMiniProgramResp *)resp];
    }
}

#pragma mark - 微信回调(处理)
/** 授权回调处理 */
+ (void)authCallbackWithResp:(nonnull SendAuthResp *)resp {
    
    /// 检查(参数)
    if (!resp) {
        return;
    }
    
    /// 检查(数据)
    if (![DryWechat sharedInstance].authBlock) {
        return;
    }
    
    /// 检查(数据)
    if (![DryWechat sharedInstance].appID || ![DryWechat sharedInstance].secret) {
        [DryWechat sharedInstance].authBlock(kDryWechatStatusCodeParamsError, nil, nil);
        return;
    }
    
    /// 获取授权数据
    NSInteger statusCode = resp.errCode;
    if (statusCode == WXSuccess) {
        
        /// 授权成功(获取openID、接口凭证)
        NSString *host = @"https://api.weixin.qq.com/sns/oauth2/access_token";
        NSString *code = resp.code;
        NSString *type = @"authorization_code";
        NSString *appID = [DryWechat sharedInstance].appID;
        NSString *secret = [DryWechat sharedInstance].secret;
        NSString *url = [NSString stringWithFormat:@"%@?appid=%@&secret=%@&code=%@&grant_type=%@", host, appID, secret, code, type];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        NSOperationQueue *queue = [NSOperationQueue mainQueue];
        [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
            
            /// 获取数据失败
            if (!data || connectionError) {
                [DryWechat sharedInstance].authBlock(kDryWechatStatusCodeUnknown, nil, nil);
                return ;
            }
            
            /// 获取原始授权数据
            id jsonObect = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers | NSJSONReadingAllowFragments error:nil];
            
            /// 原始数据检查
            if (!jsonObect || ![jsonObect isKindOfClass:[NSDictionary class]]) {
                [DryWechat sharedInstance].authBlock(kDryWechatStatusCodeUnknown, nil, nil);
                return;
            }
            
            /// 转换数据
            NSDictionary *dict = (NSDictionary *)jsonObect;
            
            /// 获取openID
            NSString *openID = nil;
            if ([[dict allKeys] containsObject:@"openid"]) {
                openID = [NSString stringWithFormat:@"%@", [dict objectForKey:@"openid"]];
            }
            
            /// 获取accessToken
            NSString *accessToken = nil;
            if ([[dict allKeys] containsObject:@"access_token"]) {
                accessToken = [NSString stringWithFormat:@"%@", [dict objectForKey:@"access_token"]];
            }
            
            /// 返回数据
            [DryWechat sharedInstance].authBlock(kDryWechatStatusCodeSuccess, openID, accessToken);
        }];
        
    }else {
        
        /// 授权失败
        switch (statusCode) {
            case WXErrCodeSentFail:{
                [DryWechat sharedInstance].authBlock(kDryWechatStatusCodeSendFail, nil, nil);
            }break;
            case WXErrCodeAuthDeny:{
                [DryWechat sharedInstance].authBlock(kDryWechatStatusCodeAuthDeny, nil, nil);
            }break;
            case WXErrCodeUnsupport:{
                [DryWechat sharedInstance].authBlock(kDryWechatStatusCodeUnsupport, nil, nil);
            }break;
            case WXErrCodeUserCancel:{
                [DryWechat sharedInstance].authBlock(kDryWechatStatusCodeUserCancel, nil, nil);
            }break;
            default:{
                [DryWechat sharedInstance].authBlock(kDryWechatStatusCodeUnknown, nil, nil);
            }break;
        }
    }
}

/** 支付回调处理 */
+ (void)payCallbackWithResp:(nonnull PayResp *)resp {
    
    /// 检查(参数)
    if (!resp) {
        return;
    }
    
    /// 检查(数据)
    if (![DryWechat sharedInstance].statusCodeBlock) {
        return;
    }
    
    /// 支付回调
    NSInteger statusCode = resp.errCode;
    switch (statusCode) {
        case WXSuccess:{
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatStatusCodeSuccess);
        }break;
        case WXErrCodeSentFail:{
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatStatusCodeSendFail);
        }break;
        case WXErrCodeAuthDeny:{
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatStatusCodeAuthDeny);
        }break;
        case WXErrCodeUnsupport:{
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatStatusCodeUnsupport);
        }break;
        case WXErrCodeUserCancel:{
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatStatusCodeUserCancel);
        }break;
        default:{
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatStatusCodeUnknown);
        }break;
    }
}

/** 分享回调处理 */
+ (void)shareCallbackWithResp:(nonnull SendMessageToWXResp *)resp {
    
    /// 检查(参数)
    if (!resp) {
        return;
    }
    
    /// 检查(数据)
    if (![DryWechat sharedInstance].statusCodeBlock) {
        return;
    }
    
    /// 分享回调
    NSInteger statusCode = resp.errCode;
    switch (statusCode) {
        case WXSuccess:{
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatStatusCodeSuccess);
        }break;
        case WXErrCodeSentFail:{
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatStatusCodeSendFail);
        }break;
        case WXErrCodeAuthDeny:{
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatStatusCodeAuthDeny);
        }break;
        case WXErrCodeUnsupport:{
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatStatusCodeUnsupport);
        }break;
        case WXErrCodeUserCancel:{
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatStatusCodeUserCancel);
        }break;
        default:{
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatStatusCodeUnknown);
        }break;
    }
}

/** 分享微信小程序回调处理 */
+ (void)shareMiniProgramCallbackWithResp:(nonnull WXLaunchMiniProgramResp *)resp {
    
    /// 检查(参数)
    if (!resp) {
        return;
    }
    
    /// 检查(数据)
    if (![DryWechat sharedInstance].ShareMiniProgramBlock) {
        return;
    }
    
    /// 小程序回调
    NSInteger statusCode = resp.errCode;
    NSString *msg = resp.extMsg;
    [DryWechat sharedInstance].ShareMiniProgramBlock(statusCode, msg);
}

@end


