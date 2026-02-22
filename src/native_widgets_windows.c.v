// Copyright (c) 2020-2025 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a MIT license
// that can be found in the LICENSE file.
module ui

// Native Win32 widget bindings for Windows.
// Uses standard Win32 controls (BUTTON, EDIT, STATIC, msctls_progress32).

#flag windows -lgdi32
#flag windows -lcomctl32

fn C.GetParent(hwnd voidptr) voidptr
fn C.CreateWindowExW(ex_style u32, class_name &u16, window_name &u16, style u32, x int, y int, w int, h int, parent voidptr, menu voidptr, instance voidptr, param voidptr) voidptr
fn C.DestroyWindow(hwnd voidptr) bool
fn C.SetWindowTextW(hwnd voidptr, text &u16) bool
fn C.MoveWindow(hwnd voidptr, x int, y int, w int, h int, repaint bool) bool
fn C.SendMessageW(hwnd voidptr, msg u32, wparam usize, lparam isize) isize
fn C.GetWindowTextW(hwnd voidptr, buf &u16, max_count int) int
fn C.GetWindowTextLengthW(hwnd voidptr) int
fn C.EnableWindow(hwnd voidptr, enable bool) bool
fn C.ShowWindow(hwnd voidptr, cmd_show int) bool
fn C.IsWindowVisible(hwnd voidptr) bool

const ws_child = u32(0x40000000)
const ws_visible = u32(0x10000000)
const ws_tabstop = u32(0x00010000)
const ws_border = u32(0x00800000)
const ws_group = u32(0x00020000)
const es_autohscroll = u32(0x0080)
const es_password = u32(0x0020)
const bs_autocheckbox = u32(0x0003)
const bs_autoradiobutton = u32(0x0009)
const bs_pushbutton = u32(0x0000)
const bm_setcheck = u32(0x00F1)
const bm_getcheck = u32(0x00F0)
const bst_checked = usize(0x0001)
const bst_unchecked = usize(0x0000)
const pbm_setrange32 = u32(0x0406)
const pbm_setpos = u32(0x0402)
const sw_show = 5
const sw_hide = 0
const icc_progress_class = u32(0x00000020)
const wm_setfont = u32(0x0030)
const ss_left = u32(0x0000)

fn win32_button_class() &u16 {
	return 'BUTTON'.to_wide()
}

fn win32_edit_class() &u16 {
	return 'EDIT'.to_wide()
}

fn win32_static_class() &u16 {
	return 'STATIC'.to_wide()
}

fn win32_progress_class() &u16 {
	return 'msctls_progress32'.to_wide()
}

pub fn (mut nw NativeWidgets) init_parent(window_handle voidptr) {
	nw.parent_handle = window_handle
}

pub fn (mut nw NativeWidgets) create_button(x int, y int, w int, h int, title string) NativeWidget {
	handle := C.CreateWindowExW(0, win32_button_class(), title.to_wide(), ws_child | ws_visible | ws_tabstop | bs_pushbutton,
		x, y, w, h, nw.parent_handle, unsafe { nil }, unsafe { nil }, unsafe { nil })
	return NativeWidget{
		handle: handle
	}
}

pub fn (nw &NativeWidgets) update_button(nwidget &NativeWidget, x int, y int, w int, h int, title string) {
	C.MoveWindow(nwidget.handle, x, y, w, h, true)
	C.SetWindowTextW(nwidget.handle, title.to_wide())
}

pub fn (mut nw NativeWidgets) create_textfield(x int, y int, w int, h int, placeholder string) NativeWidget {
	handle := C.CreateWindowExW(0, win32_edit_class(), ''.to_wide(), ws_child | ws_visible | ws_tabstop | ws_border | es_autohscroll,
		x, y, w, h, nw.parent_handle, unsafe { nil }, unsafe { nil }, unsafe { nil })
	return NativeWidget{
		handle: handle
	}
}

pub fn (nw &NativeWidgets) update_textfield(nwidget &NativeWidget, x int, y int, w int, h int, text string, placeholder string) {
	C.MoveWindow(nwidget.handle, x, y, w, h, true)
	C.SetWindowTextW(nwidget.handle, text.to_wide())
}

pub fn (nw &NativeWidgets) textfield_set_secure(nwidget &NativeWidget, secure bool) {
	// Win32 password style must be set at creation time.
	// This is a hint for future creation.
}

pub fn (mut nw NativeWidgets) create_checkbox(x int, y int, w int, h int, title string, checked bool) NativeWidget {
	handle := C.CreateWindowExW(0, win32_button_class(), title.to_wide(), ws_child | ws_visible | ws_tabstop | bs_autocheckbox,
		x, y, w, h, nw.parent_handle, unsafe { nil }, unsafe { nil }, unsafe { nil })
	if checked {
		C.SendMessageW(handle, bm_setcheck, bst_checked, 0)
	}
	return NativeWidget{
		handle: handle
	}
}

pub fn (nw &NativeWidgets) update_checkbox(nwidget &NativeWidget, x int, y int, w int, h int, title string, checked bool) {
	C.MoveWindow(nwidget.handle, x, y, w, h, true)
	C.SetWindowTextW(nwidget.handle, title.to_wide())
	C.SendMessageW(nwidget.handle, bm_setcheck, if checked { bst_checked } else { bst_unchecked },
		0)
}

pub fn (mut nw NativeWidgets) create_radio_group(x int, y int, w int, h int, values []string, selected int, title string) NativeWidget {
	// For Win32, we create individual radio buttons. We store the first radio's handle.
	// The container is simulated via a group of controls at specific positions.
	mut first_handle := unsafe { voidptr(nil) }
	item_h := 20
	for i, val in values {
		style := ws_child | ws_visible | ws_tabstop | bs_autoradiobutton | if i == 0 {
			ws_group
		} else {
			u32(0)
		}
		handle := C.CreateWindowExW(0, win32_button_class(), val.to_wide(), style,
			x, y + i * item_h, w, item_h, nw.parent_handle, unsafe { nil }, unsafe { nil },
			unsafe { nil })
		if i == selected {
			C.SendMessageW(handle, bm_setcheck, bst_checked, 0)
		}
		if i == 0 {
			first_handle = handle
		}
	}
	return NativeWidget{
		handle: first_handle
	}
}

pub fn (nw &NativeWidgets) update_radio_group(nwidget &NativeWidget, x int, y int, w int, h int, selected int) {
	// Simplified: just move the first radio button. Full implementation would track all handles.
	C.MoveWindow(nwidget.handle, x, y, w, h, true)
}

pub fn (mut nw NativeWidgets) create_progressbar(x int, y int, w int, h int, min f64, max f64, val f64) NativeWidget {
	handle := C.CreateWindowExW(0, win32_progress_class(), ''.to_wide(), ws_child | ws_visible,
		x, y, w, h, nw.parent_handle, unsafe { nil }, unsafe { nil }, unsafe { nil })
	C.SendMessageW(handle, pbm_setrange32, usize(int(min)), isize(int(max)))
	C.SendMessageW(handle, pbm_setpos, usize(int(val)), 0)
	return NativeWidget{
		handle: handle
	}
}

pub fn (nw &NativeWidgets) update_progressbar(nwidget &NativeWidget, x int, y int, w int, h int, val f64) {
	C.MoveWindow(nwidget.handle, x, y, w, h, true)
	C.SendMessageW(nwidget.handle, pbm_setpos, usize(int(val)), 0)
}

pub fn (mut nw NativeWidgets) create_label(x int, y int, w int, h int, text string) NativeWidget {
	handle := C.CreateWindowExW(0, win32_static_class(), text.to_wide(), ws_child | ws_visible | ss_left,
		x, y, w, h, nw.parent_handle, unsafe { nil }, unsafe { nil }, unsafe { nil })
	return NativeWidget{
		handle: handle
	}
}

pub fn (nw &NativeWidgets) update_label(nwidget &NativeWidget, x int, y int, w int, h int, text string) {
	C.MoveWindow(nwidget.handle, x, y, w, h, true)
	C.SetWindowTextW(nwidget.handle, text.to_wide())
}

// Win32 additional constants
const tbs_horz = u32(0x0000)
const tbs_vert = u32(0x0002)
const tbm_setrangemin = u32(0x0407)
const tbm_setrangemax = u32(0x0408)
const tbm_setpos_tb = u32(0x0405)
const cbs_dropdownlist = u32(0x0003)
const cb_addstring = u32(0x0143)
const cb_setcursel = u32(0x014E)
const lbs_notify = u32(0x0001)
const lbs_hasstrings = u32(0x0040)
const lb_addstring = u32(0x0180)
const lb_setcursel = u32(0x0186)
const ws_vscroll = u32(0x00200000)
const ss_bitmap = u32(0x000E)

fn win32_trackbar_class() &u16 {
	return 'msctls_trackbar32'.to_wide()
}

fn win32_combobox_class() &u16 {
	return 'COMBOBOX'.to_wide()
}

fn win32_listbox_class() &u16 {
	return 'LISTBOX'.to_wide()
}

pub fn (mut nw NativeWidgets) create_slider(x int, y int, w int, h int, orientation Orientation, min f64, max f64, val f64) NativeWidget {
	style := ws_child | ws_visible | ws_tabstop | if orientation == .horizontal {
		tbs_horz
	} else {
		tbs_vert
	}
	handle := C.CreateWindowExW(0, win32_trackbar_class(), ''.to_wide(), style, x, y,
		w, h, nw.parent_handle, unsafe { nil }, unsafe { nil }, unsafe { nil })
	C.SendMessageW(handle, tbm_setrangemin, usize(0), isize(int(min)))
	C.SendMessageW(handle, tbm_setrangemax, usize(0), isize(int(max)))
	C.SendMessageW(handle, tbm_setpos_tb, usize(1), isize(int(val)))
	return NativeWidget{
		handle: handle
	}
}

pub fn (nw &NativeWidgets) update_slider(nwidget &NativeWidget, x int, y int, w int, h int, val f64) {
	C.MoveWindow(nwidget.handle, x, y, w, h, true)
	C.SendMessageW(nwidget.handle, tbm_setpos_tb, usize(1), isize(int(val)))
}

pub fn (mut nw NativeWidgets) create_dropdown(x int, y int, w int, h int, items []string, selected int) NativeWidget {
	handle := C.CreateWindowExW(0, win32_combobox_class(), ''.to_wide(), ws_child | ws_visible | ws_tabstop | cbs_dropdownlist,
		x, y, w, h * 8, nw.parent_handle, unsafe { nil }, unsafe { nil }, unsafe { nil })
	for item in items {
		C.SendMessageW(handle, cb_addstring, usize(0), isize(item.to_wide()))
	}
	if selected >= 0 {
		C.SendMessageW(handle, cb_setcursel, usize(selected), 0)
	}
	return NativeWidget{
		handle: handle
	}
}

pub fn (nw &NativeWidgets) update_dropdown(nwidget &NativeWidget, x int, y int, w int, h int, selected int) {
	C.MoveWindow(nwidget.handle, x, y, w, h * 8, true)
	if selected >= 0 {
		C.SendMessageW(nwidget.handle, cb_setcursel, usize(selected), 0)
	}
}

pub fn (mut nw NativeWidgets) create_listbox(x int, y int, w int, h int, items []string, selected int) NativeWidget {
	handle := C.CreateWindowExW(0, win32_listbox_class(), ''.to_wide(), ws_child | ws_visible | ws_tabstop | ws_border | ws_vscroll | lbs_notify | lbs_hasstrings,
		x, y, w, h, nw.parent_handle, unsafe { nil }, unsafe { nil }, unsafe { nil })
	for item in items {
		C.SendMessageW(handle, lb_addstring, usize(0), isize(item.to_wide()))
	}
	if selected >= 0 {
		C.SendMessageW(handle, lb_setcursel, usize(selected), 0)
	}
	return NativeWidget{
		handle: handle
	}
}

pub fn (nw &NativeWidgets) update_listbox(nwidget &NativeWidget, x int, y int, w int, h int, selected int) {
	C.MoveWindow(nwidget.handle, x, y, w, h, true)
	if selected >= 0 {
		C.SendMessageW(nwidget.handle, lb_setcursel, usize(selected), 0)
	}
}

pub fn (mut nw NativeWidgets) create_switch(x int, y int, w int, h int, open bool) NativeWidget {
	handle := C.CreateWindowExW(0, win32_button_class(), ''.to_wide(), ws_child | ws_visible | ws_tabstop | bs_autocheckbox,
		x, y, w, h, nw.parent_handle, unsafe { nil }, unsafe { nil }, unsafe { nil })
	if open {
		C.SendMessageW(handle, bm_setcheck, bst_checked, 0)
	}
	return NativeWidget{
		handle: handle
	}
}

pub fn (nw &NativeWidgets) update_switch(nwidget &NativeWidget, x int, y int, w int, h int, open bool) {
	C.MoveWindow(nwidget.handle, x, y, w, h, true)
	C.SendMessageW(nwidget.handle, bm_setcheck, if open { bst_checked } else { bst_unchecked },
		0)
}

pub fn (mut nw NativeWidgets) create_picture(x int, y int, w int, h int, path string) NativeWidget {
	// Win32 STATIC with SS_BITMAP - simplified, just creates the control
	handle := C.CreateWindowExW(0, win32_static_class(), ''.to_wide(), ws_child | ws_visible | ss_bitmap,
		x, y, w, h, nw.parent_handle, unsafe { nil }, unsafe { nil }, unsafe { nil })
	return NativeWidget{
		handle: handle
	}
}

pub fn (nw &NativeWidgets) update_picture(nwidget &NativeWidget, x int, y int, w int, h int) {
	C.MoveWindow(nwidget.handle, x, y, w, h, true)
}

pub fn (mut nw NativeWidgets) create_menu(x int, y int, w int, h int, items []string) NativeWidget {
	// Win32 menus are typically attached to the window frame via HMENU.
	// For simplicity, we create button-based menu items.
	mut first_handle := unsafe { voidptr(nil) }
	count := items.len
	item_w := if count > 0 { w / count } else { w }
	for i, item in items {
		handle := C.CreateWindowExW(0, win32_button_class(), item.to_wide(), ws_child | ws_visible | bs_pushbutton,
			x + i * item_w, y, item_w, h, nw.parent_handle, unsafe { nil }, unsafe { nil },
			unsafe { nil })
		if i == 0 {
			first_handle = handle
		}
	}
	return NativeWidget{
		handle: first_handle
	}
}

pub fn (nw &NativeWidgets) remove_widget(nwidget &NativeWidget) {
	C.DestroyWindow(nwidget.handle)
}
