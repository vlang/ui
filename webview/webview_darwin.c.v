module webview

#flag darwin -framework WebKit
#include "@VROOT/webview/webview_darwin.m"

fn C.new_darwin_web_view(url string, title string) voidptr

// fn create_darwin_web_view(url string, title string) {
// C.new_darwin_web_view(url, title)
//}
fn C.darwin_webview_eval_js(obj voidptr, js string, result &string) string

fn C.darwin_webview_load(obj voidptr, url string)

fn C.darwin_webview_close()

pub fn (w &WebView) eval_js(s string, result &string) {
	C.darwin_webview_eval_js(w.obj, s, result)
}

pub fn (w &WebView) load(url string) {
	C.darwin_webview_load(w.obj, url)
}

fn C.darwin_delete_all_cookies()

pub fn delete_all_cookies() {
	C.darwin_delete_all_cookies()
}
