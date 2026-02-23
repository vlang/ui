// Copyright (c) 2020-2025 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a MIT license
// that can be found in the LICENSE file.
module ui

// Native Cocoa widget bindings for macOS.
// Implementation is in native_widgets_darwin.m

#include "@VROOT/src/native_widgets_darwin.m"

// Window / container
fn C.vui_native_get_content_view(window voidptr) voidptr

// Button
fn C.vui_native_create_button(parent voidptr, x int, y int, w int, h int, title &char) voidptr
fn C.vui_native_update_button(handle voidptr, x int, y int, w int, h int, title &char)
fn C.vui_native_button_set_callback(handle voidptr, callback fn (voidptr), v_button voidptr)
fn C.vui_native_button_set_enabled(handle voidptr, enabled bool)
fn C.vui_native_remove_view(handle voidptr)

// TextField (TextBox)
fn C.vui_native_create_textfield(parent voidptr, x int, y int, w int, h int, placeholder &char) voidptr
fn C.vui_native_update_textfield(handle voidptr, x int, y int, w int, h int, text &char, placeholder &char)
fn C.vui_native_textfield_get_text(handle voidptr) &char
fn C.vui_native_textfield_set_secure(handle voidptr, secure bool)

// CheckBox
fn C.vui_native_create_checkbox(parent voidptr, x int, y int, w int, h int, title &char, checked bool) voidptr
fn C.vui_native_update_checkbox(handle voidptr, x int, y int, w int, h int, title &char, checked bool)
fn C.vui_native_checkbox_is_checked(handle voidptr) bool

// Radio (uses a group of NSButton with radio style)
fn C.vui_native_create_radio_group(parent voidptr, x int, y int, w int, h int, values &&char, count int, selected int, title &char) voidptr
fn C.vui_native_update_radio_group(handle voidptr, x int, y int, w int, h int, selected int)
fn C.vui_native_radio_get_selected(handle voidptr) int

// ProgressBar (NSProgressIndicator)
fn C.vui_native_create_progressbar(parent voidptr, x int, y int, w int, h int, min f64, max f64, val f64) voidptr
fn C.vui_native_update_progressbar(handle voidptr, x int, y int, w int, h int, val f64)

// Label (NSTextField non-editable)
fn C.vui_native_create_label(parent voidptr, x int, y int, w int, h int, text &char) voidptr
fn C.vui_native_update_label(handle voidptr, x int, y int, w int, h int, text &char)

// -- Platform-specific NativeWidgets methods --

pub fn (mut nw NativeWidgets) init_parent(window_handle voidptr) {
	nw.parent_handle = C.vui_native_get_content_view(window_handle)
}

pub fn (mut nw NativeWidgets) create_button(x int, y int, w int, h int, title string) NativeWidget {
	handle := C.vui_native_create_button(nw.parent_handle, x, y, w, h, &char(title.str))
	return NativeWidget{
		handle: handle
	}
}

pub fn (nw &NativeWidgets) button_set_callback(nwidget &NativeWidget, callback fn (voidptr), v_button voidptr) {
	C.vui_native_button_set_callback(nwidget.handle, callback, v_button)
}

pub fn (nw &NativeWidgets) update_button(nwidget &NativeWidget, x int, y int, w int, h int, title string) {
	C.vui_native_update_button(nwidget.handle, x, y, w, h, &char(title.str))
}

pub fn (mut nw NativeWidgets) create_textfield(x int, y int, w int, h int, placeholder string) NativeWidget {
	handle := C.vui_native_create_textfield(nw.parent_handle, x, y, w, h, &char(placeholder.str))
	return NativeWidget{
		handle: handle
	}
}

pub fn (nw &NativeWidgets) update_textfield(nwidget &NativeWidget, x int, y int, w int, h int, text string, placeholder string) {
	C.vui_native_update_textfield(nwidget.handle, x, y, w, h, &char(text.str), &char(placeholder.str))
}

pub fn (nw &NativeWidgets) textfield_set_secure(nwidget &NativeWidget, secure bool) {
	C.vui_native_textfield_set_secure(nwidget.handle, secure)
}

pub fn (mut nw NativeWidgets) create_checkbox(x int, y int, w int, h int, title string, checked bool) NativeWidget {
	handle := C.vui_native_create_checkbox(nw.parent_handle, x, y, w, h, &char(title.str),
		checked)
	return NativeWidget{
		handle: handle
	}
}

pub fn (nw &NativeWidgets) update_checkbox(nwidget &NativeWidget, x int, y int, w int, h int, title string, checked bool) {
	C.vui_native_update_checkbox(nwidget.handle, x, y, w, h, &char(title.str), checked)
}

pub fn (mut nw NativeWidgets) create_radio_group(x int, y int, w int, h int, values []string, selected int, title string) NativeWidget {
	mut ptrs := unsafe { []&char{len: values.len} }
	for i, v in values {
		ptrs[i] = &char(v.str)
	}
	handle := C.vui_native_create_radio_group(nw.parent_handle, x, y, w, h, ptrs.data,
		values.len, selected, &char(title.str))
	return NativeWidget{
		handle: handle
	}
}

pub fn (nw &NativeWidgets) update_radio_group(nwidget &NativeWidget, x int, y int, w int, h int, selected int) {
	C.vui_native_update_radio_group(nwidget.handle, x, y, w, h, selected)
}

pub fn (mut nw NativeWidgets) create_progressbar(x int, y int, w int, h int, min f64, max f64, val f64) NativeWidget {
	handle := C.vui_native_create_progressbar(nw.parent_handle, x, y, w, h, min, max,
		val)
	return NativeWidget{
		handle: handle
	}
}

pub fn (nw &NativeWidgets) update_progressbar(nwidget &NativeWidget, x int, y int, w int, h int, val f64) {
	C.vui_native_update_progressbar(nwidget.handle, x, y, w, h, val)
}

pub fn (mut nw NativeWidgets) create_label(x int, y int, w int, h int, text string) NativeWidget {
	handle := C.vui_native_create_label(nw.parent_handle, x, y, w, h, &char(text.str))
	return NativeWidget{
		handle: handle
	}
}

pub fn (nw &NativeWidgets) update_label(nwidget &NativeWidget, x int, y int, w int, h int, text string) {
	C.vui_native_update_label(nwidget.handle, x, y, w, h, &char(text.str))
}

// Slider (NSSlider)
fn C.vui_native_create_slider(parent voidptr, x int, y int, w int, h int, horizontal bool, min f64, max f64, val f64) voidptr
fn C.vui_native_update_slider(handle voidptr, x int, y int, w int, h int, val f64)
fn C.vui_native_slider_get_value(handle voidptr) f64

// Dropdown (NSPopUpButton)
fn C.vui_native_create_dropdown(parent voidptr, x int, y int, w int, h int, items &&char, count int, selected int) voidptr
fn C.vui_native_update_dropdown(handle voidptr, x int, y int, w int, h int, selected int)
fn C.vui_native_dropdown_get_selected(handle voidptr) int

// ListBox (NSScrollView + NSTableView simplified as NSPopUpButton list)
fn C.vui_native_create_listbox(parent voidptr, x int, y int, w int, h int, items &&char, count int, selected int) voidptr
fn C.vui_native_update_listbox(handle voidptr, x int, y int, w int, h int, selected int)
fn C.vui_native_listbox_get_selected(handle voidptr) int

// Switch (NSSwitch / NSButton toggle)
fn C.vui_native_create_switch(parent voidptr, x int, y int, w int, h int, open bool) voidptr
fn C.vui_native_update_switch(handle voidptr, x int, y int, w int, h int, open bool)
fn C.vui_native_switch_is_open(handle voidptr) bool

// Picture (NSImageView)
fn C.vui_native_create_picture(parent voidptr, x int, y int, w int, h int, path &char) voidptr
fn C.vui_native_update_picture(handle voidptr, x int, y int, w int, h int)

// Menu (NSView-based menu bar)
fn C.vui_native_create_menu(parent voidptr, x int, y int, w int, h int, items &&char, count int) voidptr

pub fn (mut nw NativeWidgets) create_slider(x int, y int, w int, h int, orientation Orientation, min f64, max f64, val f64) NativeWidget {
	horizontal := orientation == .horizontal
	handle := C.vui_native_create_slider(nw.parent_handle, x, y, w, h, horizontal, min,
		max, val)
	return NativeWidget{
		handle: handle
	}
}

pub fn (nw &NativeWidgets) update_slider(nwidget &NativeWidget, x int, y int, w int, h int, val f64) {
	C.vui_native_update_slider(nwidget.handle, x, y, w, h, val)
}

pub fn (mut nw NativeWidgets) create_dropdown(x int, y int, w int, h int, items []string, selected int) NativeWidget {
	mut ptrs := unsafe { []&char{len: items.len} }
	for i, v in items {
		ptrs[i] = &char(v.str)
	}
	handle := C.vui_native_create_dropdown(nw.parent_handle, x, y, w, h, ptrs.data, items.len,
		selected)
	return NativeWidget{
		handle: handle
	}
}

pub fn (nw &NativeWidgets) update_dropdown(nwidget &NativeWidget, x int, y int, w int, h int, selected int) {
	C.vui_native_update_dropdown(nwidget.handle, x, y, w, h, selected)
}

pub fn (mut nw NativeWidgets) create_listbox(x int, y int, w int, h int, items []string, selected int) NativeWidget {
	mut ptrs := unsafe { []&char{len: items.len} }
	for i, v in items {
		ptrs[i] = &char(v.str)
	}
	handle := C.vui_native_create_listbox(nw.parent_handle, x, y, w, h, ptrs.data, items.len,
		selected)
	return NativeWidget{
		handle: handle
	}
}

pub fn (nw &NativeWidgets) update_listbox(nwidget &NativeWidget, x int, y int, w int, h int, selected int) {
	C.vui_native_update_listbox(nwidget.handle, x, y, w, h, selected)
}

pub fn (mut nw NativeWidgets) create_switch(x int, y int, w int, h int, open bool) NativeWidget {
	handle := C.vui_native_create_switch(nw.parent_handle, x, y, w, h, open)
	return NativeWidget{
		handle: handle
	}
}

pub fn (nw &NativeWidgets) update_switch(nwidget &NativeWidget, x int, y int, w int, h int, open bool) {
	C.vui_native_update_switch(nwidget.handle, x, y, w, h, open)
}

pub fn (mut nw NativeWidgets) create_picture(x int, y int, w int, h int, path string) NativeWidget {
	handle := C.vui_native_create_picture(nw.parent_handle, x, y, w, h, &char(path.str))
	return NativeWidget{
		handle: handle
	}
}

pub fn (nw &NativeWidgets) update_picture(nwidget &NativeWidget, x int, y int, w int, h int) {
	C.vui_native_update_picture(nwidget.handle, x, y, w, h)
}

pub fn (mut nw NativeWidgets) create_menu(x int, y int, w int, h int, items []string) NativeWidget {
	mut ptrs := unsafe { []&char{len: items.len} }
	for i, v in items {
		ptrs[i] = &char(v.str)
	}
	handle := C.vui_native_create_menu(nw.parent_handle, x, y, w, h, ptrs.data, items.len)
	return NativeWidget{
		handle: handle
	}
}

// -- Getters: read interactive state from native widgets --

pub fn (nw &NativeWidgets) textfield_get_text(nwidget &NativeWidget) string {
	cstr := C.vui_native_textfield_get_text(nwidget.handle)
	if cstr == unsafe { nil } {
		return ''
	}
	return unsafe { cstr.vstring() }
}

pub fn (nw &NativeWidgets) checkbox_is_checked(nwidget &NativeWidget) bool {
	return C.vui_native_checkbox_is_checked(nwidget.handle)
}

pub fn (nw &NativeWidgets) radio_get_selected(nwidget &NativeWidget) int {
	return C.vui_native_radio_get_selected(nwidget.handle)
}

pub fn (nw &NativeWidgets) slider_get_value(nwidget &NativeWidget) f64 {
	return C.vui_native_slider_get_value(nwidget.handle)
}

pub fn (nw &NativeWidgets) dropdown_get_selected(nwidget &NativeWidget) int {
	return C.vui_native_dropdown_get_selected(nwidget.handle)
}

pub fn (nw &NativeWidgets) listbox_get_selected(nwidget &NativeWidget) int {
	return C.vui_native_listbox_get_selected(nwidget.handle)
}

pub fn (nw &NativeWidgets) switch_is_open(nwidget &NativeWidget) bool {
	return C.vui_native_switch_is_open(nwidget.handle)
}

pub fn (nw &NativeWidgets) remove_widget(nwidget &NativeWidget) {
	C.vui_native_remove_view(nwidget.handle)
}
