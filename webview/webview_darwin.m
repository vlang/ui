// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.

#import <WebKit/WebKit.h>

NSString* nsstring(string);

@interface MyBrowserDelegate : NSObject <WKNavigationDelegate> {
@public
  // NSWindow *parent_window;
  // void (*nav_finished_fn)(string);
  // string js_on_init;
}
@end

@implementation MyBrowserDelegate
@end

NSWindow* g_webview_window;

void* new_darwin_web_view(string url, string title) {
  [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
  bool enable_js = 1;
  WKPreferences *prefs = [[WKPreferences alloc] init];
//  if (!enable_js) {
//    prefs.javaScriptEnabled = NO;
//  }
  // Create a configuration for the preferences
  WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
  config.preferences = prefs;
  NSRect frame = NSMakeRect(0, 0, 950, 800);
  WKWebView *webView =
      [[WKWebView alloc] initWithFrame:frame
                         // MyBrowser* webView = [[MyBrowser alloc]
                         // initWithFrame:frame //ns->view.frame
                         configuration:config];
webView.customUserAgent = @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.89 Safari/537.36";

  //[webView retain];
  // Create a new window
  NSUInteger style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                     NSWindowStyleMaskMiniaturizable |
                     NSWindowStyleMaskResizable;

  NSRect window_rect =
      NSMakeRect(0, 0, 1000, 600); //_sapp.window_width, _sapp.window_height);
  g_webview_window =
      [[NSWindow alloc] initWithContentRect:window_rect
                                  styleMask:style
                                    backing:NSBackingStoreBuffered
                                      defer:NO];
  g_webview_window.title = nsstring(title);
  g_webview_window.releasedWhenClosed = false;

  MyBrowserDelegate *del = [[MyBrowserDelegate alloc] init];
  // del->parent_window = ns->w;
  // del->nav_finished_fn = cfg.nav_finished_fn;
  // del->js_on_init = cfg.js_on_init;
  [webView setNavigationDelegate:del];
  // webView.navigationDelegate = ns->view;
  NSURL *nsurl = [NSURL URLWithString:nsstring(url)];
  NSURLRequest *nsrequest = [NSURLRequest requestWithURL:nsurl];
  //[ns->view addSubview:webView];
  [webView loadRequest:nsrequest];
  NSLog([webView title]);

  // Window controller
  // NSWindowController *windowController =
  // [[NSWindowController alloc] initWithWindow:window];

  //[NSApp activateIgnoringOtherApps:YES];
  [g_webview_window setContentView:webView];
  [g_webview_window makeKeyAndOrderFront:nil];
return         (__bridge void *)(  webView );
}

void darwin_webview_eval_js(void* web_view_, string js, string* resultt) {
	WKWebView* web_view = (__bridge WKWebView*)(web_view_);

	//__block NSString *resultString = nil;
//    __block BOOL finished = NO;

	//[web_view evaluateJavaScript:@"document.body.hidden=true;" completionHandler:nil];
	[web_view evaluateJavaScript:nsstring(js) completionHandler:^(id result, NSError *error) {
        NSLog(@"DA RESULT = %@", result);
//       finished = YES;
if (result != nil) {
    *resultt = string_clone(tos2([result UTF8String]));
   }
}];

//while (!finished)
//    {
//        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
//    }
}

void darwin_webview_load(void* web_view_, string url) {
	WKWebView* web_view = (__bridge WKWebView*)(web_view_);
  NSURL *nsurl = [NSURL URLWithString:nsstring(url)];
  NSURLRequest *nsrequest = [NSURLRequest requestWithURL:nsurl];
  [web_view loadRequest:nsrequest];
 }

void darwin_webview_close() {
	[g_webview_window close];
}


void darwin_delete_all_cookies() {
	NSHTTPCookie *cookie;
NSHTTPCookieStorage *cookieJar =
[NSHTTPCookieStorage sharedHTTPCookieStorage];
NSArray *cookies = [cookieJar cookies];
for (cookie in cookies) {
[cookieJar deleteCookie:cookie];
}

}
