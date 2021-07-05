// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.
module webview
import ui

[heap]
struct WebView {
	// widget ui.Widget
	url string
	obj voidptr
mut:
	nav_finished_fn NavFinishedFn
}

type NavFinishedFn = fn (url string)

pub struct Config {
	url   string
	title string
	// parent          &ui.Window
mut:
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
		obj = C.new_windows_web_view(cfg.url.str, cfg.title.str)
	}
	return &WebView{
		url: cfg.url
		obj: obj
		nav_finished_fn: cfg.nav_finished_fn
	}
}

pub fn exec(scriptSource string) {
	$if windows {
		C.exec(scriptSource.str)
	}
}

pub fn (mut wv WebView) on_navigate(callback NavFinishedFn) {
	wv.nav_finished_fn = callback
}

pub fn navigate(url string) {
	C.navigate(url.str)
}

pub fn (w &WebView) close() {
	$if macos {
		C.darwin_webview_close()
	}
	$if linux {
		// Untested: not sure!
		C.gtk_main_quit()
	}
	$if windows {
		C.windows_webview_close()
	}
}
