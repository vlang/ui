// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

#include "@VROOT/ui_darwin.m"

fn C.vui_message_box(s string)

fn C.vui_notify(title string, msg string)

fn C.vui_wait_events()

fn C.vui_bundle_path() string

fn C.vui_take_screenshot(string)

fn C.vui_screenshot(voidptr, string)

// fn C.darwin_draw_string(s string)
pub fn message_box(s string) {
	C.vui_message_box(s)
}

pub fn notify(title string, msg string) {
	C.vui_notify(title, msg)
}

/*
pub fn text_width(s string) int {
	return 0
}
*/
pub fn bundle_path() string {
	return C.vui_bundle_path()
}

pub fn wait_events() {
	C.vui_wait_events()
}

// pub fn take_snapshot(s string) {
// 	win := sapp.macos_get_window()
// 	// C.vui_take_screenshot( s)
// 	C.vui_screenshot(win, s)
// }
