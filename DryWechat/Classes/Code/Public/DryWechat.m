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

#pragma mark - 常量
/// 单例
static DryWechat *theInstance = nil;
/// 微信授权类型
static NSString *const kAuthScope = @"snsapi_message,snsapi_userinfo,snsapi_friend,snsapi_contact";

#pragma mark - DryWechat
@interface DryWechat() <WXApiDelegate>

/// 客户端是否注册成功
@property (nonatomic, readwrite, assign) BOOL isClientRegister;
/// 微信开放平台下发的账号
@property (nonatomic, readwrite, copy, nullable) NSString *appID;
/// 微信开放平台下发的账号密钥
@property (nonatomic, readwrite, copy, nullable) NSString *secret;
/// 商家向财付通申请的商家id
@property (nonatomic, readwrite, copy, nullable) NSString *partnerID;
/// 商家根据财付通文档填写的数据和签名
@property (nonatomic, readwrite, copy, nullable) NSString *package;
/// 商户密钥
@property (nonatomic, readwrite, copy, nullable) NSString *partnerKey;
/// 授权回调
@property (nonatomic, readwrite, copy, nullable) BlockDryWechatAuth authBlock;
/// 状态码回调
@property (nonatomic, readwrite, copy, nullable) BlockDryWechatCode statusCodeBlock;
/// 分享小程序回调
@property (nonatomic, readwrite, copy, nullable) BlockDryWechatProgram openProgramBlock;

@end

@implementation DryWechat

/// 单例
+ (instancetype)sharedInstance {
    
    if (!theInstance) {
        static dispatch_once_t oncePredicate;
        dispatch_once(&oncePredicate, ^{
            theInstance = [[DryWechat alloc] init];
        });
    }
    
    return theInstance;
}

/// 构造
- (instancetype)init {
    
    self = [super init];
    if (self) {
        
    }
    
    return self;
}

/// 析构
- (void)dealloc {
    
}

#pragma mark - 客户端
/// 注册微信客户端
+ (void)registerClientWithAppID:(nonnull NSString *)appID
                         secret:(nullable NSString *)secret
                      partnerID:(nullable NSString *)partnerID
                     partnerKey:(nullable NSString *)partnerKey
                        package:(nullable NSString *)package {

    /// 注册
    [DryWechat sharedInstance].isClientRegister = [WXApi registerApp:appID];
    
    /// 保存数据
    [DryWechat sharedInstance].appID = appID;
    [DryWechat sharedInstance].secret = secret;
    [DryWechat sharedInstance].partnerID = partnerID;
    [DryWechat sharedInstance].package = package;
    [DryWechat sharedInstance].partnerKey = partnerKey;
}

/// 处理微信通过URL启动App时传递的数据
+ (BOOL)handleOpenURL:(nullable NSURL *)url {
    
    if (url) {
        return [WXApi handleOpenURL:url delegate:[DryWechat sharedInstance]];
    }
    
    return NO;
}

/// 微信客户端是否安装
+ (BOOL)isWXAppInstalled {
    return [WXApi isWXAppInstalled];
}

/// 微信客户端是否支持OpenApi
+ (BOOL)isWXAppSupportApi {
    return [WXApi isWXAppSupportApi];
}

#pragma mark - 授权、获取用户信息
/// 申请授权(获取: OpenID、接口凭证)
+ (void)applyAuthAt:(nonnull UIViewController *)vc completion:(nonnull BlockDryWechatAuth)completion {
    
    /// 检查数据
    if (!completion) {
        return;
    }
    
    /// 检查(客户端是否注册成功)
    if (![DryWechat sharedInstance].isClientRegister) {
        completion(kDryWechatCodeNoRegister, nil, nil);
        return;
    }
    
    /// 检查(必要参数)
    if (![DryWechat sharedInstance].appID || ![DryWechat sharedInstance].secret) {
        completion(kDryWechatCodeParamsErr, nil, nil);
        return;
    }
    
    /// 检查(客户端是否安装)
    if (![DryWechat isWXAppInstalled]) {
        completion(kDryWechatCodeNotInstall, nil, nil);
        return;
    }
    
    /// 检查(客户端是否支持)
    if (![DryWechat isWXAppSupportApi]) {
        completion(kDryWechatCodeUnsupport, nil, nil);
        return;
    }
    
    /// 更新Block
    [DryWechat sharedInstance].authBlock = completion;
    
    /// 发送Auth请求到微信
    SendAuthReq *authReq = [[SendAuthReq alloc] init];
    authReq.scope = kAuthScope;
    authReq.state = [[NSBundle mainBundle] bundleIdentifier];
    authReq.openID = [DryWechat sharedInstance].appID;
    [WXApi sendAuthReq:authReq viewController:vc delegate:[DryWechat sharedInstance]];
}

/// 获取微信的用户信息(昵称、头像地址)
+ (void)userInfoWithOpenID:(nonnull NSString *)openID
               accessToken:(nonnull NSString *)accessToken
                completion:(nonnull BlockDryWechatUserInfo)completion {
    
    /// 检查数据
    if (!completion) {
        return;
    }
    
    /// 检查(客户端是否注册成功)
    if (![DryWechat sharedInstance].isClientRegister) {
        completion(kDryWechatCodeNoRegister, nil, nil);
        return;
    }
    
    /// 检查(必要参数)
    if (!openID || !accessToken) {
        completion(kDryWechatCodeParamsErr, nil, nil);
        return;
    }
    
    /// 请求用户信息
    NSString *host = @"https://api.weixin.qq.com/sns/userinfo";
    NSString *url = [NSString stringWithFormat:@"%@?access_token=%@&openid=%@", host, accessToken, openID];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        /// 获取数据失败
        if (!data || connectionError) {
            completion(kDryWechatCodeUnknown, nil, nil);
            return ;
        }
        
        /// 原始数据检查
        id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers | NSJSONReadingAllowFragments error:nil];
        if (!json || ![json isKindOfClass:[NSDictionary class]]) {
            completion(kDryWechatCodeUnknown, nil, nil);
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
        completion(kDryWechatCodeSuccess, nickName, headImgURL);
    }];
}

#pragma mark - 支付
/// 将字符串转换成MD5
+ (NSString *)md5FromString:(NSString *)aString {
    
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

/// @说明 创建发起支付时的签名(sign)
/// @参数 appID:      微信开放平台下发的账号
/// @参数 partnerID:  商家向财付通申请的商家id
/// @参数 partnerKey: 商户密钥
/// @参数 package:    商家根据财付通文档填写的数据和签名
/// @参数 prepayID:   预支付订单号(服务端下发)
/// @参数 noncestr:   随机串(服务端下发)
/// @参数 timestamp:  当前时间戳
/// @返回 NSString
+ (NSString *)signWithAppID:(NSString *)appID
                  partnerID:(NSString *)partnerID
                 partnerKey:(NSString *)partnerKey
                    package:(NSString *)package
                   prepayID:(NSString *)prepayID
                   noncestr:(NSString *)noncestr
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

/// 支付(调起微信客户端支付，不支持网页)
+ (void)payWithPrepayID:(nonnull NSString *)prepayID
               noncestr:(nonnull NSString *)noncestr
             completion:(nonnull BlockDryWechatCode)completion {
    
    /// 检查数据
    if (!completion) {
        return;
    }
    
    /// 检查(客户端是否注册成功)
    if (![DryWechat sharedInstance].isClientRegister) {
        completion(kDryWechatCodeNoRegister);
        return;
    }
    
    /// 检查(必要参数)
    if (![DryWechat sharedInstance].appID
        || ![DryWechat sharedInstance].partnerID
        || ![DryWechat sharedInstance].package
        || ![DryWechat sharedInstance].partnerKey) {
        completion(kDryWechatCodeParamsErr);
        return;
    }
    
    /// 检查(客户端是否安装)
    if (![DryWechat isWXAppInstalled]) {
        completion(kDryWechatCodeNotInstall);
        return;
    }
    
    /// 检查(客户端是否支持)
    if (![DryWechat isWXAppSupportApi]) {
        completion(kDryWechatCodeUnsupport);
        return;
    }
    
    /// 检查(支付参数)
    if (!prepayID || !noncestr) {
        completion(kDryWechatCodeParamsErr);
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
        completion(kDryWechatCodeParamsErr);
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

#pragma mark - 分享
/// 分享文本信息
+ (void)shareTextWithScene:(DryWechatScene)scene
                      text:(nonnull NSString *)text
                completion:(nonnull BlockDryWechatCode)completion {
    
    /// 检查数据
    if (!completion) {
        return;
    }
    
    /// 检查(客户端是否注册成功)
    if (![DryWechat sharedInstance].isClientRegister) {
        completion(kDryWechatCodeNoRegister);
        return;
    }
    
    /// 检查(客户端是否安装)
    if (![DryWechat isWXAppInstalled]) {
        completion(kDryWechatCodeNotInstall);
        return;
    }
    
    /// 检查(客户端是否支持)
    if (![DryWechat isWXAppSupportApi]) {
        completion(kDryWechatCodeUnsupport);
        return;
    }
    
    /// 检查(分享参数)
    if (!text) {
        completion(kDryWechatCodeParamsErr);
        return;
    }
    
    /// 更新Block
    [DryWechat sharedInstance].statusCodeBlock = completion;
    
    /// 分享文本信息 */
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.bText = YES;
    req.text = text;
    if (scene == kDryWechatScenePerson) {
        req.scene = WXSceneSession;
    }else if (scene == kDryWechatSceneTimeline) {
        req.scene = WXSceneTimeline;
    }else {
        req.scene = WXSceneFavorite;
    }
    [WXApi sendReq:req];
}

/// 分享多媒体信息
+ (void)shareMediaWithScene:(DryWechatScene)scene
                      title:(nullable NSString *)title
                    descrip:(nullable NSString *)descrip
                 thumbImage:(nullable UIImage *)thumbImage
                  mediaType:(DryWechatMediaType)mediaType
                      media:(nonnull DryWechatMedia *)media
                 completion:(nonnull BlockDryWechatCode)completion {
    
    /// 检查(参数)
    if (!completion) {
        return;
    }
    
    /// 检查(客户端是否注册成功)
    if (![DryWechat sharedInstance].isClientRegister) {
        completion(kDryWechatCodeNoRegister);
        return;
    }
    
    /// 检查(客户端是否安装)
    if (![DryWechat isWXAppInstalled]) {
        completion(kDryWechatCodeNotInstall);
        return;
    }
    
    /// 检查(客户端是否支持)
    if (![DryWechat isWXAppSupportApi]) {
        completion(kDryWechatCodeUnsupport);
        return;
    }
    
    /// 检查(分享参数)
    if (!media) {
        completion(kDryWechatCodeParamsErr);
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
    if (mediaType == kDryWechatMediaTypeImage) {
        
        /// 图片
        WXImageObject *mediaObject = [WXImageObject object];
        if (media.imageData) {
            mediaObject.imageData = media.imageData;
        }
        targetMessage.mediaObject = mediaObject;
        
    }else if (mediaType == kDryWechatMediaTypeMusic) {
        
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
        
    }else if (mediaType == kDryWechatMediaTypeVideo) {
        
        /// 视频
        WXVideoObject *mediaObject = [WXVideoObject object];
        if (media.videoUrl) {
            mediaObject.videoUrl = media.videoUrl;
        }
        if (media.videoLowBandUrl) {
            mediaObject.videoLowBandUrl = media.videoLowBandUrl;
        }
        targetMessage.mediaObject = mediaObject;
        
    }else if (mediaType == kDryWechatMediaTypeWebpage) {
        
        /// 网页
        WXWebpageObject *mediaObject = [WXWebpageObject object];
        if (media.webpageUrl) {
            mediaObject.webpageUrl = media.webpageUrl;
        }
        targetMessage.mediaObject = mediaObject;
        
    }else if (mediaType == kDryWechatMediaTypeAppExtend) {
        
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
        
    }else if (mediaType == kDryWechatMediaTypeEmoticon) {
        
        /// 表情
        WXEmoticonObject *mediaObject = [WXEmoticonObject object];
        if (media.emoticonData) {
            mediaObject.emoticonData = media.emoticonData;
        }
        targetMessage.mediaObject = mediaObject;
        
    }else if (mediaType == kDryWechatMediaTypeFile) {
        
        /// 文件
        WXFileObject *mediaObject = [WXFileObject object];
        if (media.tfileExtension) {
            mediaObject.fileExtension = media.tfileExtension;
        }
        if (media.tfileData) {
            mediaObject.fileData = media.tfileData;
        }
        targetMessage.mediaObject = mediaObject;
        
    }else if (mediaType == kDryWechatMediaTypeLocation) {
        
        /// 地理位置
        WXLocationObject *mediaObject = [WXLocationObject object];
        if (media.lng) {
            mediaObject.lng = [media.lng doubleValue];
        }
        if (media.lat) {
            mediaObject.lat = [media.lat doubleValue];
        }
        targetMessage.mediaObject = mediaObject;
        
    }else if (mediaType == kDryWechatMediaTypeText) {
        
        /// 文本
        WXTextObject *mediaObject = [WXTextObject object];
        if (media.contentText) {
            mediaObject.contentText = media.contentText;
        }
        targetMessage.mediaObject = mediaObject;
    }

    /// 设置分享多媒体对象
    req.message = targetMessage;
    
    /// 分享多媒体信息
    [WXApi sendReq:req];
}

#pragma mark - 打开微信小程序
+ (void)openProgramWithUserName:(nonnull NSString *)userName
                           path:(nullable NSString *)path
                           type:(DryWechatProgram)type
                     completion:(nonnull BlockDryWechatProgram)completion {
    
    /// 检查(参数)
    if (!completion) {
        return;
    }
    
    /// 检查(客户端是否注册成功)
    if (![DryWechat sharedInstance].isClientRegister) {
        completion(kDryWechatCodeNoRegister, nil);
        return;
    }
    
    /// 检查(客户端是否安装)
    if (![DryWechat isWXAppInstalled]) {
        completion(kDryWechatCodeNotInstall, nil);
        return;
    }
    
    /// 检查(客户端是否支持)
    if (![DryWechat isWXAppSupportApi]) {
        completion(kDryWechatCodeUnsupport, nil);
        return;
    }
    
    /// 检查(参数)
    if (!userName) {
        completion(kDryWechatCodeParamsErr, nil);
        return;
    }
    
    /// 更新Block
    [DryWechat sharedInstance].openProgramBlock = completion;
    
    /// 创建请求
    WXLaunchMiniProgramReq *launchMiniProgramReq = [WXLaunchMiniProgramReq object];
    launchMiniProgramReq.userName = userName;
    
    if (path) {
        launchMiniProgramReq.path = path;
    }
    
    if (type == kDryWechatProgramTest) {
        launchMiniProgramReq.miniProgramType = WXMiniProgramTypeTest;
    }else if (type == kDryWechatProgramPreview) {
        launchMiniProgramReq.miniProgramType = WXMiniProgramTypePreview;
    }else {
        launchMiniProgramReq.miniProgramType = WXMiniProgramTypeRelease;
    }
    
    /// 打开小程序
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

/// 授权回调处理
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
        [DryWechat sharedInstance].authBlock(kDryWechatCodeParamsErr, nil, nil);
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
                [DryWechat sharedInstance].authBlock(kDryWechatCodeUnknown, nil, nil);
                return ;
            }
            
            /// 获取原始授权数据
            id jsonObect = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers | NSJSONReadingAllowFragments error:nil];
            
            /// 原始数据检查
            if (!jsonObect || ![jsonObect isKindOfClass:[NSDictionary class]]) {
                [DryWechat sharedInstance].authBlock(kDryWechatCodeUnknown, nil, nil);
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
            [DryWechat sharedInstance].authBlock(kDryWechatCodeSuccess, openID, accessToken);
        }];
        
    }else {
        
        /// 授权失败
        switch (statusCode) {
            case WXErrCodeSentFail:{
                [DryWechat sharedInstance].authBlock(kDryWechatCodeSendFail, nil, nil);
            }break;
            case WXErrCodeAuthDeny:{
                [DryWechat sharedInstance].authBlock(kDryWechatCodeAuthDeny, nil, nil);
            }break;
            case WXErrCodeUnsupport:{
                [DryWechat sharedInstance].authBlock(kDryWechatCodeUnsupport, nil, nil);
            }break;
            case WXErrCodeUserCancel:{
                [DryWechat sharedInstance].authBlock(kDryWechatCodeUserCancel, nil, nil);
            }break;
            default:{
                [DryWechat sharedInstance].authBlock(kDryWechatCodeUnknown, nil, nil);
            }break;
        }
    }
}

/// 支付回调处理
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
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatCodeSuccess);
        }break;
        case WXErrCodeSentFail:{
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatCodeSendFail);
        }break;
        case WXErrCodeAuthDeny:{
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatCodeAuthDeny);
        }break;
        case WXErrCodeUnsupport:{
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatCodeUnsupport);
        }break;
        case WXErrCodeUserCancel:{
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatCodeUserCancel);
        }break;
        default:{
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatCodeUnknown);
        }break;
    }
}

/// 分享回调处理
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
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatCodeSuccess);
        }break;
        case WXErrCodeSentFail:{
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatCodeSendFail);
        }break;
        case WXErrCodeAuthDeny:{
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatCodeAuthDeny);
        }break;
        case WXErrCodeUnsupport:{
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatCodeUnsupport);
        }break;
        case WXErrCodeUserCancel:{
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatCodeUserCancel);
        }break;
        default:{
            [DryWechat sharedInstance].statusCodeBlock(kDryWechatCodeUnknown);
        }break;
    }
}

/// 打开微信小程序回调处理
+ (void)shareMiniProgramCallbackWithResp:(nonnull WXLaunchMiniProgramResp *)resp {
    
    /// 检查(参数)
    if (!resp) {
        return;
    }
    
    /// 检查(数据)
    if (![DryWechat sharedInstance].openProgramBlock) {
        return;
    }
    
    /// 小程序回调
    NSInteger statusCode = resp.errCode;
    NSString *msg = resp.extMsg;
    [DryWechat sharedInstance].openProgramBlock(statusCode, msg);
}

@end


