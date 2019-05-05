# DryWechat
iOS: 微信功能简化(登录、支付、分享、打开小程序)
[微信开放平台](https://open.weixin.qq.com/cgi-bin/showdocument?action=dir_list&t=resource/res_list&verify=1&id=1417694084&token=&lang=zh_CN)


## Prerequisites
* Xcode 10.2.1
* iOS 9.0 or later
* ObjC、Swift 5 or later


## Installation
* pod 'DryWechat'
* Targets => Info => URL Types添加scheme( identifier:"weixin"、URL Schemes:"wx+AppID" )
* info.plist文件属性LSApplicationQueriesSchemes中增加weixin、wechat字段


## Features
### 注册客户端
```
注册客户端
[DryWechat registerClientWithAppID:""
                            secret:nil
                         partnerID:nil
                        partnerKey:nil
                           package:nil];
接收回调信息
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {

    [DryWechat handleOpenURL:url];
    return YES;
}
```
### 获取授权(登录)
```
[DryWechat applyAuthAt:vc completion:^(DryWechatCode code, NSString * _Nullable openID, NSString * _Nullable accessToken) {
    
}];
```
### 获取用户信息
```
[DryWechat userInfoWithOpenID:"" accessToken:"" completion:^(DryWechatCode code, NSString * _Nullable nickName, NSString * _Nullable headImgURL) {

}];
```
### 支付
```
[DryWechat payWithPrepayID:"" noncestr:"" completion:^(DryWechatCode code) {

}];
```
###  分享文本
```
[DryWechat shareTextWithScene:kDryWechatScenePerson text:"" completion:^(DryWechatCode code) {

}];
```
###  分享多媒体
```
DryWechatMedia *mediaObj = [[DryWechatMedia alloc] init];
[DryWechat shareMediaWithScene:kDryWechatScenePerson title:"" descrip:"" thumbImage:"" mediaType:kDryWechatMediaTypeImage media:mediaObj completion:^(DryWechatCode code) {

}];
```
### 打开小程序
```
[DryWechat openProgramWithUserName:"" path:nil type:kDryWechatProgramRelease completion:^(DryWechatCode code, NSString * _Nullable msg) {

}];
```
