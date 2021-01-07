module webview

#flag darwin -framework WebKit
#include "@VROOT/webview/webview_darwin.m"
fn C.new_darwin_web_view(s string) voidptr

// fn create_darwin_web_view(url string, title string) {
// C.new_darwin_web_view(url, title)
//}
fn C.darwin_webview_eval_js(js string)

fn C.darwin_webview_load(url string)

pub fn (w &WebView) eval_js(s string) {
	C.darwin_webview_eval_js(w.obj, s)
}

pub fn (w &WebView) load(url string) {
	C.darwin_webview_load(w.obj, url)
}
