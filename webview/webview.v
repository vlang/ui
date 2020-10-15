// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.
module webview

// import ui
#flag darwin -framework WebKit
#include "@VROOT/webview/webview_darwin.m"
// fn C.webview_create(voidptr, voidptr)
struct WebView {
	// widget ui.Widget
	url string
}

type NavFinishedFn = fn (url string)

fn C.new_darwin_web_view(s string)

pub struct Cfg {
	url             string
	title           string
	// parent          &ui.Window
	nav_finished_fn webview.NavFinishedFn
	// js_on_init      string
}

pub fn new_window(cfg Cfg) &WebView {
	$if macos {
		C.new_darwin_web_view(cfg.url, cfg.title)
	}
	$if linux {
		println('webview not implemented on linux yet')
	}
	$if windows {
		println('webview not implemented on windows yet')
	}
	return &WebView{
		url: cfg.url
	}
}
