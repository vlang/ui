// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.
module webview

// import ui
struct WebView {
	// widget ui.Widget
	url string
}

type NavFinishedFn = fn (url string)

pub struct Cfg {
	url             string
	title           string
	// parent          &ui.Window
	nav_finished_fn NavFinishedFn
	// js_on_init      string
}

pub fn new_window(cfg Cfg) &WebView {
	$if macos {
		create_darwin_web_view(cfg.url, cfg.title)
	}
	$if linux {
		new_linux_web_view(cfg.url, cfg.title)
	}
	$if windows {
		println('webview not implemented on windows yet')
	}
	return &WebView{
		url: cfg.url
	}
}
