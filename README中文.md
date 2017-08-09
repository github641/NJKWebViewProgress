# NJKWebViewProgress

NJKWebViewProgress是一个为UIWebView设计的进度接口类库。
当前（只类库开发并开源的时候，目前17年8月9日也没有，而且Apple早就提供了WebKit），UIWebView没有一个官方的进度接口。你可以在你的app内置浏览器中使用这个模块，来添加进度条。


<img src="https://raw.github.com/ninjinkun/NJKWebViewProgress/master/DemoApp/Screenshot/screenshot1.png" alt="iOS ScreenShot 1" width="240px" style="width: 240px;" />

NJKWebViewProgress 没有使用 CocoaTouch的私有方法。它是可以安全通过AppStore审核的。

# Used in Production
- [Yahoo! JAPAN](https://itunes.apple.com/app/yahoo!-japan/id299147843?mt=8)
- [Facebook](https://itunes.apple.com/app/facebook/id284882215?mt=8‎)

# Requirements
- iOS 4.3 or later
- ARC

# Usage
Instance `NJKWebViewProgress` and set `UIWebViewDelegate`. If you set `webViewProxyDelegate`, `NJKWebViewProgress` should perform as a proxy object.

```objc
_progressProxy = [[NJKWebViewProgress alloc] init]; // instance variable
webView.delegate = _progressProxy;
_progressProxy.webViewProxyDelegate = self;
_progressProxy.progressDelegate = self;
```

When UIWebView start loading, `NJKWebViewProgress` call delegate method and block with progress.
```objc
-(void)webViewProgress:(NJKWebViewProgress *)webViewProgress updateProgress:(float)progress
{
    [progressView setProgress:progress animated:NO];
}
```

```objc
progressProxy.progressBlock = ^(float progress) {
    [progressView setProgress:progress animated:NO];
};
```

You can determine the current state of the document by comparing the `progress` value to one of the provided constants:

```objc
-(void)webViewProgress:(NJKWebViewProgress *)webViewProgress updateProgress:(float)progress
{
    if (progress == NJKInteractiveProgressValue) {
        // The web view has finished parsing the document,
        // but is still loading sub-resources
    }
}
```

This repository contains iOS 7 Safari style bar `NJKWebViewProgressView`. You can choose `NJKWebViewProgressView`, `UIProgressView` or your custom bar.

# Install
## CocoaPods

```
pod 'NJKWebViewProgress'
```

# License
[Apache]: http://www.apache.org/licenses/LICENSE-2.0
[MIT]: http://www.opensource.org/licenses/mit-license.php
[GPL]: http://www.gnu.org/licenses/gpl.html
[BSD]: http://opensource.org/licenses/bsd-license.php
[MIT license][MIT].
