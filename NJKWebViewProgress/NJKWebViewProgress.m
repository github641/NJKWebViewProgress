//
//  NJKWebViewProgress.m
//
//  Created by Satoshi Aasano on 4/20/13.
//  Copyright (c) 2013 Satoshi Asano. All rights reserved.
//

#import "NJKWebViewProgress.h"

NSString *completeRPCURLPath = @"/njkwebviewprogressproxy/complete";

const float NJKInitialProgressValue = 0.1f;
const float NJKInteractiveProgressValue = 0.5f;
const float NJKFinalProgressValue = 0.9f;

@implementation NJKWebViewProgress
{
    NSUInteger _loadingCount;
    NSUInteger _maxLoadCount;
    NSURL *_currentURL;
    BOOL _interactive;
}

- (id)init
{
    self = [super init];
    if (self) {
        _maxLoadCount = _loadingCount = 0;
        _interactive = NO;
    }
    return self;
}

- (void)startProgress
{
    if (_progress < NJKInitialProgressValue) {
        [self setProgress:NJKInitialProgressValue];
    }
}

- (void)incrementProgress
{
    float progress = self.progress;
    float maxProgress = _interactive ? NJKFinalProgressValue : NJKInteractiveProgressValue;
    float remainPercent = (float)_loadingCount / (float)_maxLoadCount;
    float increment = (maxProgress - progress) * remainPercent;
    progress += increment;
    // 这个函数返回，参数中的最小值
    progress = fmin(progress, maxProgress);
    [self setProgress:progress];
}

- (void)completeProgress
{
    [self setProgress:1.0];
}

- (void)setProgress:(float)progress
{
    // progress should be incremental only
    if (progress > _progress || progress == 0) {
        _progress = progress;
        if ([_progressDelegate respondsToSelector:@selector(webViewProgress:updateProgress:)]) {
            [_progressDelegate webViewProgress:self updateProgress:progress];
        }
        if (_progressBlock) {
            _progressBlock(progress);
        }
    }
}

- (void)reset
{
    _maxLoadCount = _loadingCount = 0;
    _interactive = NO;
    [self setProgress:0.0];
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    // 进入这个大括号，加载完成
    if ([request.URL.path isEqualToString:completeRPCURLPath]) {
        [self completeProgress];
        return NO;
    }
    
    // ret为最终返回后结果
    BOOL ret = YES;
    
    // 进入这个大括号，是遵守UIWebViewDelegate对象的属性是否实现了协议里的这个方法，如果实现了，那么将目标UIWebView所在的控制器的delegate方法中返回的值，取到
    if ([_webViewProxyDelegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        ret = [_webViewProxyDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    
    // 准备参数 isFragmentJump的值
    BOOL isFragmentJump = NO;
    /* lzy注170809：
     
     
     The fragment component of a URL is the component after a # symbol. For example, in the URL http://www.example.com/index.html#jumpLocation, the fragment is jumpLocation.
     
     The fragment identifier, conforming to RFC 1808. (read-only)
     This property contains the URL’s fragment. Any percent-encoded characters are not unescaped. If the receiver does not conform to RFC 1808, this property contains nil.
     
     Availability	iOS (2.0 and later), macOS (10.0 and later), tvOS (9.0 and later), watchOS (2.0 and later)
     */
    if (request.URL.fragment) {// 如果url中存在fragment，那么移除『#fragment』
        NSString *nonFragmentURL = [request.URL.absoluteString stringByReplacingOccurrencesOfString:[@"#" stringByAppendingString:request.URL.fragment] withString:@""];
        // 对fragment替换为空之后，如果替换后的str与URL.absoluteString相同，说明之前就没有fragment，大括号本身是因为有fragment进来的，所以，这个值一般是NO
        isFragmentJump = [nonFragmentURL isEqualToString:webView.request.URL.absoluteString];
    }

    // 是原始请求，还是页面的子部件
    /* lzy注170809：
     The main document URL associated with the request.
     This URL is used for the cookie “same domain as main document” policy.
     
     Availability	iOS (2.0 and later), macOS (10.2 and later), tvOS (9.0 and later), watchOS (2.0 and later)
     
     可以到StackOverFlow搜索『what is the difference between nsurlrequests maindocumenturl and url properties』。
     
     */
    BOOL isTopLevelNavigation = [request.mainDocumentURL isEqual:request.URL];

    // 是本地文件还是 http请求
    BOOL isHTTPOrLocalFile = [request.URL.scheme isEqualToString:@"http"] || [request.URL.scheme isEqualToString:@"https"] || [request.URL.scheme isEqualToString:@"file"];
    
    // 当网页重新加载时 && !fragment跳转 && 是本地文件或者HTTP请求 && 原始请求页面
    // 重置进度
    if (ret && !isFragmentJump && isHTTPOrLocalFile && isTopLevelNavigation) {
        _currentURL = request.URL;
        [self reset];
    }
    return ret;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if ([_webViewProxyDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [_webViewProxyDelegate webViewDidStartLoad:webView];
    }

    // 进入此代理方法,正在加载数+1，取最大值赋值给最大加载数
    _loadingCount++;
    _maxLoadCount = fmax(_maxLoadCount, _loadingCount);

    // 进度条进度初始化
    [self startProgress];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if ([_webViewProxyDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [_webViewProxyDelegate webViewDidFinishLoad:webView];
    }
    
    // 正在加载数-1、降低进度
    _loadingCount--;
    [self incrementProgress];
    // 执行JavaScript，获得当前页面的readyState（准备状态）
    /* lzy注170809：关于readyState的有关资料
     http://blog.sina.com.cn/s/blog_686ec64701014xar.html
     https://developer.mozilla.org/zh-CN/docs/Web/API/Document/readyState
     
     interactive：文档已经完成加载，文档已被解析，但是诸如图像，样式表和框架之类的子资源仍在加载。
     */
    NSString *readyState = [webView stringByEvaluatingJavaScriptFromString:@"document.readyState"];

    BOOL interactive = [readyState isEqualToString:@"interactive"];
    if (interactive) {// 如果是这个状态，那么注入一个JS来观察加载完成状态
        _interactive = YES;
        NSString *waitForCompleteJS = [NSString stringWithFormat:@"window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '%@://%@%@'; document.body.appendChild(iframe);  }, false);", webView.request.mainDocumentURL.scheme, webView.request.mainDocumentURL.host, completeRPCURLPath];
        [webView stringByEvaluatingJavaScriptFromString:waitForCompleteJS];
    }
    // 是否被重定向
    BOOL isNotRedirect = _currentURL && [_currentURL isEqual:webView.request.mainDocumentURL];
    // 是否完成加载
    BOOL complete = [readyState isEqualToString:@"complete"];
    if (complete && isNotRedirect) {// 没有重定向 && 页面加载完成
        [self completeProgress];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if ([_webViewProxyDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [_webViewProxyDelegate webView:webView didFailLoadWithError:error];
    }
    
    // 加载失败，正在加载数-1
    _loadingCount--;
    // 增加进度条进度
    [self incrementProgress];

    /* lzy注170809：
     与前一个代理方法- (void)webViewDidFinishLoad:一样，获取文档准备状态，如果为interactive，那么注入JS检查页面完成状态
     */
    NSString *readyState = [webView stringByEvaluatingJavaScriptFromString:@"document.readyState"];

    BOOL interactive = [readyState isEqualToString:@"interactive"];
    if (interactive) {
        _interactive = YES;
        NSString *waitForCompleteJS = [NSString stringWithFormat:@"window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '%@://%@%@'; document.body.appendChild(iframe);  }, false);", webView.request.mainDocumentURL.scheme, webView.request.mainDocumentURL.host, completeRPCURLPath];
        [webView stringByEvaluatingJavaScriptFromString:waitForCompleteJS];
    }
    
    BOOL isNotRedirect = _currentURL && [_currentURL isEqual:webView.request.mainDocumentURL];
    BOOL complete = [readyState isEqualToString:@"complete"];
    if ((complete && isNotRedirect) || error) { //（没有重定向 && 页面加载完成） || 是否出错
        [self completeProgress];
    }
}

#pragma mark - 
#pragma mark Method Forwarding
// for future UIWebViewDelegate impl

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ( [super respondsToSelector:aSelector] )
        return YES;
    
    if ([self.webViewProxyDelegate respondsToSelector:aSelector])
        return YES;
    
    return NO;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    NSMethodSignature *signature = [super methodSignatureForSelector:selector];
    if(!signature) {
        if([_webViewProxyDelegate respondsToSelector:selector]) {
            return [(NSObject *)_webViewProxyDelegate methodSignatureForSelector:selector];
        }
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation*)invocation
{
    if ([_webViewProxyDelegate respondsToSelector:[invocation selector]]) {
        [invocation invokeWithTarget:_webViewProxyDelegate];
    }
}

@end
