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
