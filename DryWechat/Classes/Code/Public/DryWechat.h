//
//  DryWechat.h
//  DryWechatKit
//
//  Created by Dry on 2018/8/14.
//  Copyright © 2018 Dry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DryWechatMedia.h"

#pragma mark - DryWechatStatusCode(状态码)
typedef NS_ENUM(NSInteger, DryWechatStatusCode) {
    /// 成功
    kDryWechatStatusCodeSuccess     = 0,
    /// 未知错误
    kDryWechatStatusCodeUnknown     = -1,
    /// SDK未注册
    kDryWechatStatusCodeNoRegister  = -2,
    /// 未安装客户端
    kDryWechatStatusCodeNotInstall  = -3,
    /// 客户端不支持
    kDryWechatStatusCodeUnsupport   = -4,
    /// 发送失败
    kDryWechatStatusCodeSendFail    = -5,
    /// 用户拒绝授权
    kDryWechatStatusCodeAuthDeny    = -6,
    /// 用户点击取消并返回
    kDryWechatStatusCodeUserCancel  = -7,
    /// 参数异常
    kDryWechatStatusCodeParamsError = -8,
};

#pragma mark - DryWechatScene(分享场景类型)
typedef NS_ENUM(NSInteger, DryWechatScene) {
    /// 聊天
    kDryWechatScenePerson   = 0,
    /// 朋友圈
    kDryWechatSceneTimeline = 1,
    /// 收藏
    kDryWechatSceneFavorite = 2,
};

#pragma mark - DryWechatMiniProgramType(分享小程序类型)
typedef NS_ENUM(NSInteger, DryWechatMiniProgramType) {
    /// 正式版本
    kDryWechatMiniProgramTypeRelease    = 0,
    /// 体验版本
    kDryWechatMiniProgramTypeTest       = 1,
    /// 开发版本
    kDryWechatMiniProgramTypePreview    = 2,
};

#pragma mark - Block
/// 状态码回调
typedef void (^BlockDryWechatStatusCode) (DryWechatStatusCode code);
/// 授权回调(状态码、OpenID、接口凭证)
typedef void (^BlockDryWechatAuth) (DryWechatStatusCode code, NSString *_Nullable openID, NSString *_Nullable accessToken);
/// 用户信息回调(状态码、昵称、头像地址)
typedef void (^BlockDryWechatUserInfo) (DryWechatStatusCode code, NSString *_Nullable nickName, NSString *_Nullable headImgURL);
/// 分享小程序回调(状态码、信息)
typedef void (^BlockDryWechatShareMiniProgram) (DryWechatStatusCode code, NSString *_Nullable msg);

#pragma mark - DryWechatManager
@interface DryWechat : NSObject

/**
 * @函数说明    注册微信客户端
 * @特别说明    在application:applicationdidFinishLaunchingWithOptions:调用
 * @输入参数    appID:      微信开放平台下发的账号(注册、授权、获取用户信息、支付)
 * @输入参数    secret:     微信开放平台下发的账号密钥(授权、获取用户信息、支付)
 * @输入参数    partnerID:  商家向财付通申请的商家id(支付)
 * @输入参数    partnerKey: 商户密钥(支付)
 * @输入参数    package:    商家根据财付通文档填写的数据和签名(支付)
 * @返回数据    BOOL
 */
+ (BOOL)registerWithAppID:(nonnull NSString *)appID
                   secret:(nonnull NSString *)secret
                partnerID:(nullable NSString *)partnerID
               partnerKey:(nullable NSString *)partnerKey
                  package:(nullable NSString *)package;

/**
 * @函数说明    处理微信通过URL启动App时传递的数据
 * @使用说明    需要在application:handleOpenURL中调用
 * @返回数据    BOOL
 */
+ (BOOL)handleOpenURL:(nonnull NSURL *)url;

/**
 * @函数说明    微信客户端是否安装
 * @返回数据    BOOL
 */
+ (BOOL)isWXAppInstalled;

/**
 * @函数说明    微信客户端是否支持OpenApi
 * @返回数据    BOOL
 */
+ (BOOL)isWXAppSupportApi;

/**
 * @函数说明    申请授权(获取: OpenID、接口凭证)
 * @输出参数    completion: 授权回调
 * @返回数据    void
 */
+ (void)applyAuth:(nonnull BlockDryWechatAuth)completion;

/**
 * @函数说明    获取微信的用户信息(昵称、头像地址)
 * @输入参数    openID:         用户标识
 * @输入参数    accessToken:    接口调用凭证
 * @输出参数    completion:     用户信息回调
 * @返回数据    void
 */
+ (void)userInfoWithOpenID:(nonnull NSString *)openID
               accessToken:(nonnull NSString *)accessToken
                completion:(nonnull BlockDryWechatUserInfo)completion;

/**
 * @函数说明    支付(调起微信客户端支付，不支持网页)
 * @输入参数    prepayid:   预支付订单号(服务端下发)
 * @输入参数    noncestr:   随机串(服务端下发)
 * @输出参数    completion: 状态码回调
 * @返回数据    void
 */
+ (void)payWithPrepayID:(nonnull NSString *)prepayID
               noncestr:(nonnull NSString *)noncestr
             completion:(nonnull BlockDryWechatStatusCode)completion;

/**
 * @函数说明    分享文本信息
 * @输入参数    content:    文本信息
 * @输入参数    scene:      分享场景
 * @输出参数    completion: 状态码回调
 * @返回数据    void
 */
+ (void)shareTextWithContent:(nonnull NSString *)content
                       scene:(DryWechatScene)scene
                  completion:(nonnull BlockDryWechatStatusCode)completion;

/**
 * @函数说明    分享多媒体信息
 * @输入参数    type:       多媒体信息类型
 * @输入参数    message:    多媒体信息
 * @输入参数    scene:      分享场景
 * @输出参数    completion: 状态码回调
 * @返回数据    void
 */
+ (void)shareMediaWithType:(DryWechatMediaType)type
                     media:(nonnull DryWechatMedia *)media
                     scene:(DryWechatScene)scene
                completion:(nonnull BlockDryWechatStatusCode)completion;

/**
 * @函数说明    打开微信小程序
 * @输入参数    userName:   拉起的小程序的username
 * @输入参数    path:       拉起小程序页面的路径，不填默认拉起小程序首页
 * @输入参数    type:       拉起小程序的类型
 * @输出参数    completion: 状态码回调
 * @返回数据    void
 */
+ (void)shareMiniWithUserName:(nonnull NSString *)userName
                         path:(nullable NSString *)path
                         type:(DryWechatMiniProgramType)type
                   completion:(nonnull BlockDryWechatShareMiniProgram)completion;

@end


