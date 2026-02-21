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
	C.vui_native_update_textfield(nwidget.handle, x, y, w, h, &char(text.str),
		&char(placeholder.str))
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
	mut ptrs := []&char{len: values.len}
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

pub fn (nw &NativeWidgets) remove_widget(nwidget &NativeWidget) {
	C.vui_native_remove_view(nwidget.handle)
}
