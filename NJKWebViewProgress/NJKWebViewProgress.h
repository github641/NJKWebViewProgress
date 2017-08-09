//
//  NJKWebViewProgress.h
//
//  Created by Satoshi Aasano on 4/20/13.
//  Copyright (c) 2013 Satoshi Asano. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/* lzy注170809：
 对属性修饰关键字的兼容处理。
 unsafe_unretained是iOS4中使用的修饰词。
 之后退出了weak。
 使用 
 #if __has_feature(objc_arc_weak)来判断，当前运行的系统是否支持weak关键字这个特性。
 
 可以在官方文档：Transitioning to ARC Release Notes，找到更多的信息
 */
#undef njk_weak
#if __has_feature(objc_arc_weak)
#define njk_weak weak
#else
#define njk_weak unsafe_unretained
#endif

/* lzy注170809：
 对外申明三个float类型的值
 */
extern const float NJKInitialProgressValue;
extern const float NJKInteractiveProgressValue;
extern const float NJKFinalProgressValue;

/* lzy注170809：
 声明一个 无返回值，有一个形式参数是float类型的 名为 NJKWebViewProgressBlock的block
 */
typedef void (^NJKWebViewProgressBlock)(float progress);

/* lzy注170809：
 以前的很多开源类库，比较老的，比如从iOS7以及之前的，近2年没怎么维护的，很多都喜欢将protocol写在后面，只是在前面声明一下。
 而就现在来说，活跃的类库，一般都会把protocol放到 该类@interface的前面
 */
@protocol NJKWebViewProgressDelegate;

@interface NJKWebViewProgress : NSObject<UIWebViewDelegate>
/* lzy注170809：
 遵守NJKWebViewProgressDelegate协议的属性。
 注意：此处使用了njk_weak宏来修饰。这个宏是对关键字weak和unsafe_unreatained(iOS4.0)的兼容
 */
@property (nonatomic, njk_weak) id<NJKWebViewProgressDelegate>progressDelegate;
/* lzy注170809：
 遵守UIWebViewDelegate协议的属性。
 NNJKWebViewProgress还需要持有，遵守目标UIWebView的delegate的对象
 */
@property (nonatomic, njk_weak) id<UIWebViewDelegate>webViewProxyDelegate;

@property (nonatomic, copy) NJKWebViewProgressBlock progressBlock;
@property (nonatomic, readonly) float progress; // 0.0..1.0

@property (nonatomic, unsafe_unretained) NSString *a;

- (void)reset;

@end

@protocol NJKWebViewProgressDelegate <NSObject>
- (void)webViewProgress:(NJKWebViewProgress *)webViewProgress updateProgress:(float)progress;
@end

