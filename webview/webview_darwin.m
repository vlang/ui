// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a MIT license
// that can be found in the LICENSE file.

#import <WebKit/WebKit.h>

NSString *nsstring(string);
string g_vui_webview_js_val;
string g_vui_webview_cookie_val;

@interface MyBrowserDelegate : NSObject <WKNavigationDelegate> {
	//@public
  //@public
  // NSWindow *parent_window;
  // void (*nav_finished_fn)(string);
  // string js_on_init;
}
@end

@implementation MyBrowserDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
//    NSLog(@"Navigation finished");
}



@end

@interface MyScriptHandler : NSObject <WKScriptMessageHandler> {

}
@end

@implementation MyScriptHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
//    [_ObjcLog logWithFile:"[WKWebView]" function:[message.name UTF8String] line:0 color:[UIColor whiteColor] message:message.body];
puts(".m received script message");
NSLog(message.body);
g_vui_webview_js_val = string_clone(tos2([message.body UTF8String]));
//                 *resultt = string_clone(tos2([result UTF8String]));
}
@end

NSWindow *g_webview_window;

string darwin_get_webview_js_val() {
	return g_vui_webview_js_val;
}

string darwin_get_webview_cookie_val() {
	return g_vui_webview_cookie_val;
}
  MyBrowserDelegate *del ;//= [[MyBrowserDelegate alloc] init];

void *new_darwin_web_view(string url, string title, string js_on_init) {
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
  webView.customUserAgent =
//      @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/537.36 "
//      @"(KHTML, like Gecko) Chrome/84.0.4147.89 Safari/537.36";
     @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15";

  //[webView retain];
  // Create a new window
  NSUInteger style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                     NSWindowStyleMaskMiniaturizable |
                     NSWindowStyleMaskResizable;

  NSRect window_rect =
      NSMakeRect(0, 0, 1000, 800); //_sapp.window_width, _sapp.window_height);
  g_webview_window =
      [[NSWindow alloc] initWithContentRect:window_rect
                                  styleMask:style
                                    backing:NSBackingStoreBuffered
                                      defer:NO];
  g_webview_window.title = nsstring(title);
  g_webview_window.releasedWhenClosed = false;

//  MyBrowserDelegate *del = [[MyBrowserDelegate alloc] init];
  del = [[MyBrowserDelegate alloc] init];
  // del->parent_window = ns->w;
  // del->nav_finished_fn = cfg.nav_finished_fn;
  // del->js_on_init = cfg.js_on_init;
  [webView setNavigationDelegate:del];
// del.webView = webView;
  // webView.navigationDelegate = ns->view;
  NSURL *nsurl = [NSURL URLWithString:nsstring(url)];
  NSURLRequest *nsrequest = [NSURLRequest requestWithURL:nsurl];
  //[ns->view addSubview:webView];

  if (js_on_init.len > 0) {
  	NSLog(@"adding js on init");
  	[webView.configuration.userContentController addUserScript:[[WKUserScript alloc]
    initWithSource:nsstring(js_on_init)
injectionTime:WKUserScriptInjectionTimeAtDocumentStart
 forMainFrameOnly:NO]];

MyScriptHandler*  script_handler = [MyScriptHandler alloc];

    [webView.configuration.userContentController addScriptMessageHandler:script_handler
name:@"vui"];


  }


  [webView loadRequest:nsrequest];
  NSLog([webView title]);

  // Window controller
  // NSWindowController *windowController =
  // [[NSWindowController alloc] initWithWindow:window];

  //[NSApp activateIgnoringOtherApps:YES];
  [g_webview_window setContentView:webView];
  [g_webview_window makeKeyAndOrderFront:nil];
  return (__bridge void *)(webView);
}

void darwin_webview_eval_js(void *web_view_, string js) { //, string *resultt) {
  WKWebView *web_view = (__bridge WKWebView *)(web_view_);

  //__block NSString *resultString = nil;
  //    __block BOOL finished = NO;

  //[web_view evaluateJavaScript:@"document.body.hidden=true;"
  // completionHandler:nil];
  [web_view evaluateJavaScript:nsstring(js)
             completionHandler:^(id result, NSError *error) {
               NSLog(@"eval js result = %@", result);
               //       finished = YES;
               if (result != nil&& result != [NSNull null] ) {
//                 *resultt = string_clone(tos2([result UTF8String]));
g_vui_webview_js_val = string_clone(tos2([result UTF8String]));
               }
             }];

  // while (!finished)
  //     {
  //         [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
  //         beforeDate:[NSDate distantFuture]];
  //     }
}

void darwin_webview_load(void *web_view_, string url) {
  WKWebView *web_view = (__bridge WKWebView *)(web_view_);
  NSURL *nsurl = [NSURL URLWithString:nsstring(url)];
  NSURLRequest *nsrequest = [NSURLRequest requestWithURL:nsurl];
  [web_view loadRequest:nsrequest];
}

void darwin_delete_all_cookies2(void *web_view_) {
  WKWebView *web_view = (__bridge WKWebView *)(web_view_);
	// Assume webView is your WKWebView instance
WKWebsiteDataStore *dataStore = web_view.configuration.websiteDataStore;

// Fetch all website data types
NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];

// You can specify a date in the past to fetch all cookies
NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];

// Fetch data records
[dataStore fetchDataRecordsOfTypes:websiteDataTypes
                 completionHandler:^(NSArray<WKWebsiteDataRecord *> *records) {
    for (WKWebsiteDataRecord *record in records) {
        // Check if the record is for the domain you want to delete cookies for
//        if ([record.displayName containsString:@"domain-you-want-to-delete-cookies-for.com"]) {
            // Delete the cookies
            [dataStore removeDataOfTypes:record.dataTypes
                          forDataRecords:@[record]
                       completionHandler:^{
                           NSLog(@"Cookies for %@ deleted successfully", record.displayName);
                       }];
//        }
    }
}];
	}

void darwin_webview_close() { [g_webview_window close]; }

void darwin_delete_all_cookies() {
	/*
  NSHTTPCookie *cookie;
  NSHTTPCookieStorage *cookieJar =
      [NSHTTPCookieStorage sharedHTTPCookieStorage];
  NSArray *cookies = [cookieJar cookies];
  for (cookie in cookies) {
    [cookieJar deleteCookie:cookie];
  }
 */
 // Get the default website data store
WKWebsiteDataStore *dataStore = [WKWebsiteDataStore defaultDataStore];

// Fetch data types to delete
NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];

// Set the date from which to delete data (use [NSDate distantPast] to delete all data)
NSDate *dateFrom = [NSDate distantPast];

// Delete the data
[dataStore removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
    NSLog(@"All cookies deleted");
}];

}
