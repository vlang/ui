// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.

#import <WebKit/WebKit.h>

@interface MyBrowserDelegate : NSObject <WKNavigationDelegate> {
@public
  // NSWindow *parent_window;
  // void (*nav_finished_fn)(string);
  // string js_on_init;
}
@end

@implementation MyBrowserDelegate
@end

NSString *nsstring(string str) {
  return [[NSString alloc] initWithBytesNoCopy:str.str
                                        length:str.len
                                      encoding:NSUTF8StringEncoding
                                  freeWhenDone:false];
}

WKWebView *new_darwin_web_view(string url, string title) {
  [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
  bool enable_js = 1;
  WKPreferences *prefs = [[WKPreferences alloc] init];
  if (!enable_js) {
    prefs.javaScriptEnabled = NO;
  }
  // Create a configuration for the preferences
  WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
  config.preferences = prefs;
  NSRect frame = NSMakeRect(0, 0, 950, 800);
  WKWebView *webView =
      [[WKWebView alloc] initWithFrame:frame
                         // MyBrowser* webView = [[MyBrowser alloc]
                         // initWithFrame:frame //ns->view.frame
                         configuration:config];

  //[webView retain];
  // Create a new window
  NSUInteger style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                     NSWindowStyleMaskMiniaturizable |
                     NSWindowStyleMaskResizable;

  NSRect window_rect =
      NSMakeRect(0, 0, 1000, 600); //_sapp.window_width, _sapp.window_height);
  NSWindow *window =
      [[NSWindow alloc] initWithContentRect:window_rect
                                  styleMask:style
                                    backing:NSBackingStoreBuffered
                                      defer:NO];
  window.title = nsstring(title);
  window.releasedWhenClosed = false;

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
  [window setContentView:webView];
  [window makeKeyAndOrderFront:nil];
  return webView;
}
