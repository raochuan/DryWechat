//
//  DryWechatMedia.h
//  DryWechat
//
//  Created by Ruiying Duan on 2019/5/6.
//

#import <Foundation/Foundation.h>

#pragma mark - 分享多媒体类型
typedef NS_ENUM(NSInteger, DryWechatMediaType) {
    /// 图片
    kDryWechatMediaTypeImage,
    /// 音乐
    kDryWechatMediaTypeMusic,
    /// 视频
    kDryWechatMediaTypeVideo,
    /// 网页
    kDryWechatMediaTypeWebpage,
    /// App扩展
    kDryWechatMediaTypeAppExtend,
    /// 表情
    kDryWechatMediaTypeEmoticon,
    /// 文件
    kDryWechatMediaTypeFile,
    /// 地理位置
    kDryWechatMediaTypeLocation,
    /// 文本
    kDryWechatMediaTypeText,
};

#pragma mark - 分享多媒体对象
@interface DryWechatMedia : NSObject

///========== 通用属性
/// 标题(512字节)
@property (nonatomic, readwrite, nonnull, copy) NSString *title;
/// 描述内容(1K)
@property (nonatomic, readwrite, nonnull, copy) NSString *descrip;
/// 缩略图数据(32K)
@property (nonatomic, readwrite, nullable, strong) UIImage *thumbImage;

///========== 图片(kDryWechatMediaTypeImage)
/// 图片真实数据内容(10M)
@property (nonatomic, readwrite, nullable, strong) NSData *imageData;

///========== 音乐(kDryWechatMediaTypeMusic)
/// 音乐网页的url地址(10K)
@property (nonatomic, readwrite, nullable, copy) NSString *musicUrl;
/// 音乐lowband网页的url地址(10K)
@property (nonatomic, readwrite, nullable, copy) NSString *musicLowBandUrl;
/// 音乐数据url地址(10K)
@property (nonatomic, readwrite, nullable, copy) NSString *musicDataUrl;
/// 音乐lowband数据url地址(10K)
@property (nonatomic, readwrite, nullable, copy) NSString *musicLowBandDataUrl;

///========== 视频(kDryWechatMediaTypeVideo)
/// 视频网页的url地址(10K)
@property (nonatomic, readwrite, nullable, copy) NSString *videoUrl;
/// 视频lowband网页的url地址(10K)
@property (nonatomic, readwrite, nullable, copy) NSString *videoLowBandUrl;

///========== 网页(kDryWechatMediaTypeWebpage)
/// 网页的url地址(不能为空，10K)
@property (nonatomic, readwrite, nullable, copy) NSString *webpageUrl;

///========== App扩展(kDryWechatMediaTypeAppExtend)
/// App不存在，微信终端会打开该url所指的App下载地址(10K)
@property (nonatomic, readwrite, nullable, copy) NSString *url;
/// App自定义简单数据，微信会回传给App处理(2K)
@property (nonatomic, readwrite, nullable, copy) NSString *extInfo;
/// App文件数据，发送给微信好友，需要点击后下载数据，微信会回传给App处理(10M)
@property (nonatomic, readwrite, nullable, strong) NSData *fileData;

///========== 表情(kDryWechatMediaTypeEmoticon)
/// 表情真实数据内容(10M)
@property (nonatomic, readwrite, nullable, strong) NSData *emoticonData;

///========== 文件(kDryWechatMediaTypeFile)
/// 文件后缀名(64字节)
@property (nonatomic, readwrite, nullable, copy) NSString *tfileExtension;
/// 文件真实数据内容(10M)
@property (nonatomic, readwrite, nullable, strong) NSData *tfileData;

///========== 地理位置(kDryWechatMediaTypeLocation)
/// 经度
@property (nonatomic, readwrite, nullable, assign) NSString *lng;
/// 纬度
@property (nonatomic, readwrite, nullable, assign) NSString *lat;

///========== 文本(kDryWechatMediaTypeText)
/// 文本内容
@property (nonatomic, readwrite, nullable, copy) NSString *contentText;

@end
