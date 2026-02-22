// Copyright (c) 2020-2025 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a MIT license
// that can be found in the LICENSE file.
module ui

// Default (Linux/other) stub implementations for native widgets.
// On platforms without native widget support, these are no-ops
// and the framework falls back to its custom gg-based rendering.

pub fn (mut nw NativeWidgets) init_parent(window_handle voidptr) {
	nw.parent_handle = window_handle
}

pub fn (mut nw NativeWidgets) create_button(x int, y int, w int, h int, title string) NativeWidget {
	return NativeWidget{}
}

pub fn (nw &NativeWidgets) button_set_callback(nwidget &NativeWidget, callback fn (voidptr), v_button voidptr) {
}

pub fn (nw &NativeWidgets) update_button(nwidget &NativeWidget, x int, y int, w int, h int, title string) {
}

pub fn (mut nw NativeWidgets) create_textfield(x int, y int, w int, h int, placeholder string) NativeWidget {
	return NativeWidget{}
}

pub fn (nw &NativeWidgets) update_textfield(nwidget &NativeWidget, x int, y int, w int, h int, text string, placeholder string) {
}

pub fn (nw &NativeWidgets) textfield_set_secure(nwidget &NativeWidget, secure bool) {
}

pub fn (mut nw NativeWidgets) create_checkbox(x int, y int, w int, h int, title string, checked bool) NativeWidget {
	return NativeWidget{}
}

pub fn (nw &NativeWidgets) update_checkbox(nwidget &NativeWidget, x int, y int, w int, h int, title string, checked bool) {
}

pub fn (mut nw NativeWidgets) create_radio_group(x int, y int, w int, h int, values []string, selected int, title string) NativeWidget {
	return NativeWidget{}
}

pub fn (nw &NativeWidgets) update_radio_group(nwidget &NativeWidget, x int, y int, w int, h int, selected int) {
}

pub fn (mut nw NativeWidgets) create_progressbar(x int, y int, w int, h int, min f64, max f64, val f64) NativeWidget {
	return NativeWidget{}
}

pub fn (nw &NativeWidgets) update_progressbar(nwidget &NativeWidget, x int, y int, w int, h int, val f64) {
}

pub fn (mut nw NativeWidgets) create_label(x int, y int, w int, h int, text string) NativeWidget {
	return NativeWidget{}
}

pub fn (nw &NativeWidgets) update_label(nwidget &NativeWidget, x int, y int, w int, h int, text string) {
}

pub fn (mut nw NativeWidgets) create_slider(x int, y int, w int, h int, orientation Orientation, min f64, max f64, val f64) NativeWidget {
	return NativeWidget{}
}

pub fn (nw &NativeWidgets) update_slider(nwidget &NativeWidget, x int, y int, w int, h int, val f64) {
}

pub fn (mut nw NativeWidgets) create_dropdown(x int, y int, w int, h int, items []string, selected int) NativeWidget {
	return NativeWidget{}
}

pub fn (nw &NativeWidgets) update_dropdown(nwidget &NativeWidget, x int, y int, w int, h int, selected int) {
}

pub fn (mut nw NativeWidgets) create_listbox(x int, y int, w int, h int, items []string, selected int) NativeWidget {
	return NativeWidget{}
}

pub fn (nw &NativeWidgets) update_listbox(nwidget &NativeWidget, x int, y int, w int, h int, selected int) {
}

pub fn (mut nw NativeWidgets) create_switch(x int, y int, w int, h int, open bool) NativeWidget {
	return NativeWidget{}
}

pub fn (nw &NativeWidgets) update_switch(nwidget &NativeWidget, x int, y int, w int, h int, open bool) {
}

pub fn (mut nw NativeWidgets) create_picture(x int, y int, w int, h int, path string) NativeWidget {
	return NativeWidget{}
}

pub fn (nw &NativeWidgets) update_picture(nwidget &NativeWidget, x int, y int, w int, h int) {
}

pub fn (mut nw NativeWidgets) create_menu(x int, y int, w int, h int, items []string) NativeWidget {
	return NativeWidget{}
}

// -- Getters (no-op stubs) --

pub fn (nw &NativeWidgets) textfield_get_text(nwidget &NativeWidget) string {
	return ''
}

pub fn (nw &NativeWidgets) checkbox_is_checked(nwidget &NativeWidget) bool {
	return false
}

pub fn (nw &NativeWidgets) radio_get_selected(nwidget &NativeWidget) int {
	return 0
}

pub fn (nw &NativeWidgets) slider_get_value(nwidget &NativeWidget) f64 {
	return 0.0
}

pub fn (nw &NativeWidgets) dropdown_get_selected(nwidget &NativeWidget) int {
	return 0
}

pub fn (nw &NativeWidgets) listbox_get_selected(nwidget &NativeWidget) int {
	return -1
}

pub fn (nw &NativeWidgets) switch_is_open(nwidget &NativeWidget) bool {
	return false
}

pub fn (nw &NativeWidgets) remove_widget(nwidget &NativeWidget) {
}
