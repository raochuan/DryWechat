//
//  DryWechat.h
//  DryWechatKit
//
//  Created by Dry on 2018/8/14.
//  Copyright © 2018 Dry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DryWechatMedia.h"

#pragma mark - 状态码
typedef NS_ENUM(NSInteger, DryWechatCode) {
    /// 成功
    kDryWechatCodeSuccess,
    /// 未知错误
    kDryWechatCodeUnknown,
    /// SDK未注册
    kDryWechatCodeNoRegister,
    /// 未安装客户端
    kDryWechatCodeNotInstall,
    /// 客户端不支持
    kDryWechatCodeUnsupport,
    /// 发送失败
    kDryWechatCodeSendFail,
    /// 用户拒绝授权
    kDryWechatCodeAuthDeny,
    /// 用户点击取消并返回
    kDryWechatCodeUserCancel,
    /// 参数异常
    kDryWechatCodeParamsErr,
};

#pragma mark - 分享场景类型
typedef NS_ENUM(NSInteger, DryWechatScene) {
    /// 聊天
    kDryWechatScenePerson,
    /// 朋友圈
    kDryWechatSceneTimeline,
    /// 收藏
    kDryWechatSceneFavorite,
};

#pragma mark - 分享小程序类型
typedef NS_ENUM(NSInteger, DryWechatProgram) {
    /// 正式版本
    kDryWechatProgramRelease,
    /// 体验版本
    kDryWechatProgramTest,
    /// 开发版本
    kDryWechatProgramPreview,
};

#pragma mark - Block
/// 状态码回调
typedef void (^BlockDryWechatCode) (DryWechatCode code);
/// 授权回调(状态码、OpenID、接口凭证)
typedef void (^BlockDryWechatAuth) (DryWechatCode code, NSString *_Nullable openID, NSString *_Nullable accessToken);
/// 用户信息回调(状态码、昵称、头像地址)
typedef void (^BlockDryWechatUserInfo) (DryWechatCode code, NSString *_Nullable nickName, NSString *_Nullable headImgURL);
/// 分享小程序回调(状态码、信息)
typedef void (^BlockDryWechatProgram) (DryWechatCode code, NSString *_Nullable msg);

#pragma mark - DryWechatManager
@interface DryWechat : NSObject

/// @说明 注册微信客户端
/// @参数 appID:  微信开放平台下发的账号(注册、分享、授权、获取用户信息、支付)
/// @参数 secret: 微信开放平台下发的账号密钥(授权、获取用户信息)
/// @参数 partnerID:  商家向财付通申请的商家id(支付)
/// @参数 partnerKey: 商户密钥(支付)
/// @参数 package:    商家根据财付通文档填写的数据和签名(支付)
/// @返回 void
+ (void)registerClientWithAppID:(nonnull NSString *)appID
                         secret:(nullable NSString *)secret
                      partnerID:(nullable NSString *)partnerID
                     partnerKey:(nullable NSString *)partnerKey
                        package:(nullable NSString *)package;

/// @说明 处理微信通过URL启动App时传递的数据
/// @注释 在application:openURL:options:中调用
/// @返回 BOOL
+ (BOOL)handleOpenURL:(nullable NSURL *)url;

/// @说明 微信客户端是否安装
/// @返回 BOOL
+ (BOOL)isWXAppInstalled;

/// @说明 微信客户端是否支持OpenAp
/// @返回 BOOL
+ (BOOL)isWXAppSupportApi;

/// @说明 申请授权(获取: OpenID、接口凭证)
/// @参数 vc:         当前视图控制器
/// @参数 completion: 授权回调
/// @返回 void
+ (void)applyAuthAt:(nonnull UIViewController *)vc completion:(nonnull BlockDryWechatAuth)completion;

/// @说明 获取微信的用户信息(昵称、头像地址)
/// @参数 openID:         用户标识
/// @参数 accessToken:    接口调用凭证
/// @参数 completion:     用户信息回调
/// @返回 void
+ (void)userInfoWithOpenID:(nonnull NSString *)openID
               accessToken:(nonnull NSString *)accessToken
                completion:(nonnull BlockDryWechatUserInfo)completion;

/// @说明 支付(调起微信客户端支付，不支持网页)
/// @参数 prepayid:   预支付订单号(服务端下发)
/// @参数 noncestr:   随机串(服务端下发)
/// @参数 completion: 状态码回调
/// @返回 void
+ (void)payWithPrepayID:(nonnull NSString *)prepayID
               noncestr:(nonnull NSString *)noncestr
             completion:(nonnull BlockDryWechatCode)completion;

/// @说明 分享文本信息
/// @参数 scene:      分享场景
/// @参数 title:      标题(512字节)
/// @参数 descrip:    描述内容(1K)
/// @参数 thumbImage: 缩略图数据(32K)
/// @参数 text:       文本信息(大于0且小于10K)
/// @参数 completion: 状态码回调
/// @返回 void
+ (void)shareTextWithScene:(DryWechatScene)scene
                      text:(nonnull NSString *)text
                completion:(nonnull BlockDryWechatCode)completion;

/// @说明 分享多媒体信息
/// @参数 scene:      分享场景
/// @参数 title:      标题(512字节)
/// @参数 descrip:    描述内容(1K)
/// @参数 thumbImage: 缩略图数据(32K)
/// @参数 mediaType:  多媒体对象类型
/// @参数 media:      多媒体对象
/// @参数 completion: 状态码回调
/// @返回 void
+ (void)shareMediaWithScene:(DryWechatScene)scene
                      title:(nullable NSString *)title
                    descrip:(nullable NSString *)descrip
                 thumbImage:(nullable UIImage *)thumbImage
                  mediaType:(DryWechatMediaType)mediaType
                      media:(nonnull DryWechatMedia *)media
                 completion:(nonnull BlockDryWechatCode)completion;

/// @说明 打开微信小程序
/// @参数 userName:   拉起的小程序的username
/// @参数 path:       拉起小程序页面的路径，不填默认拉起小程序首页
/// @参数 type:       拉起小程序的类型
/// @参数 completion: 状态码回调
/// @返回 void
+ (void)openProgramWithUserName:(nonnull NSString *)userName
                           path:(nullable NSString *)path
                           type:(DryWechatProgram)type
                     completion:(nonnull BlockDryWechatProgram)completion;

@end


