// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.
module webview

// import ui
[heap]
struct WebView {
	// widget ui.Widget
	url string
	obj voidptr
}

type NavFinishedFn = fn (url string)

pub struct Config {
	url   string
	title string
	// parent          &ui.Window
	nav_finished_fn NavFinishedFn
	// js_on_init      string
}

pub fn new_window(cfg Config) &WebView {
	mut obj := voidptr(0)
	$if macos {
		obj = C.new_darwin_web_view(cfg.url, cfg.title)
	}
	$if linux {
		create_linux_web_view(cfg.url, cfg.title)
	}
	$if windows {
		println('webview not implemented on windows yet')
	}
	return &WebView{
		url: cfg.url
		obj: obj
	}
}

pub fn (w &WebView) close() {
	C.darwin_webview_close()
}
