module webview

#flag darwin -framework WebKit
#include "@VROOT/webview/webview_darwin.m"

fn C.new_darwin_web_view(s string)
