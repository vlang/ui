// Copyright (c) 2020-2025 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a MIT license
// that can be found in the LICENSE file.
module ui

import macos

#flag darwin -framework Cocoa

type ButtonTargetCallback = fn (voidptr)

const native_button_target_class_name = 'VUIButtonTarget'
const native_pointer_align = u8(3)
const ns_view_max_x_margin = u64(4)
const ns_view_min_y_margin = u64(8)
const ns_view_autoresize_mask = ns_view_max_x_margin | ns_view_min_y_margin
const ns_bezel_style_rounded = u64(1)
const ns_button_type_switch = u64(3)
const ns_button_type_radio = u64(4)
const ns_control_state_off = i64(0)
const ns_control_state_on = i64(1)
const ns_progress_indicator_style_bar = u64(0)
const ns_text_field_square_bezel = u64(0)
const ns_image_scale_proportionally_up_or_down = u64(3)
const ns_bezel_border = u64(2)
const native_button_target_assoc_key_name = 'vui_button_target_assoc'

const native_widgets_state_singleton = &NativeWidgetsDarwinState{
	listbox_selected: map[u64]int{}
}

@[heap]
struct NativeWidgetsDarwinState {
mut:
	listbox_selected map[u64]int
}

fn native_widgets_state() &NativeWidgetsDarwinState {
	return unsafe { &NativeWidgetsDarwinState(native_widgets_state_singleton) }
}

fn native_button_target_assoc_key() voidptr {
	return voidptr(macos.sel(native_button_target_assoc_key_name))
}

fn handle_key(handle voidptr) u64 {
	return u64(handle)
}

fn bool_to_ns(value bool) voidptr {
	if value {
		return voidptr(1)
	}
	return unsafe { nil }
}

fn control_state(value bool) i64 {
	return if value { ns_control_state_on } else { ns_control_state_off }
}

fn clear_color() macos.Id {
	return macos.msg_id(macos.get_class('NSColor'), 'clearColor')
}

fn selected_text_background_color() macos.Id {
	return macos.msg_id(macos.get_class('NSColor'), 'selectedTextBackgroundColor')
}

fn common_autoresizing(view macos.Id) {
	C.macos_objc_msg_void_u64(view, macos.sel('setAutoresizingMask:'), ns_view_autoresize_mask)
}

fn flipped_rect(parent macos.Id, x int, y int, w int, h int) macos.Rect {
	bounds := macos.msg_rect(parent, 'bounds')
	return macos.rect(f64(x), bounds.height - f64(y) - f64(h), f64(w), f64(h))
}

fn update_frame_from_parent(view macos.Id, x int, y int, w int, h int) {
	parent := macos.msg_id(view, 'superview')
	if parent == unsafe { nil } {
		return
	}
	C.macos_objc_msg_void_rect(view, macos.sel('setFrame:'), flipped_rect(parent, x, y, w, h))
}

fn button_target_clicked(self macos.Id, _cmd macos.Sel, sender macos.Id) {
	_ = _cmd
	_ = sender
	callback_ptr := C.macos_objc_get_ptr_ivar(self, c'callback_ptr')
	user_data_ptr := C.macos_objc_get_ptr_ivar(self, c'user_data_ptr')
	if callback_ptr == unsafe { nil } {
		return
	}
	callback := unsafe { ButtonTargetCallback(callback_ptr) }
	callback(user_data_ptr)
}

fn ensure_button_target_class() macos.Class {
	existing := macos.get_class(native_button_target_class_name)
	if existing != unsafe { nil } {
		return macos.Class(existing)
	}
	cls := C.macos_objc_allocate_class_pair(macos.Class(macos.get_class('NSObject')),
		&char(native_button_target_class_name.str), 0)
	assert cls != unsafe { nil }
	assert C.macos_class_add_ivar(cls, c'callback_ptr', sizeof(voidptr), native_pointer_align,
		c'^v')
	assert C.macos_class_add_ivar(cls, c'user_data_ptr', sizeof(voidptr), native_pointer_align,
		c'^v')
	assert C.macos_class_add_method(cls, macos.sel('buttonClicked:'),
		voidptr(button_target_clicked), c'v@:@')
	C.macos_objc_register_class_pair(cls)
	return cls
}

fn native_get_content_view(window voidptr) voidptr {
	return macos.msg_id(macos.Id(window), 'contentView')
}

fn native_create_button(parent voidptr, x int, y int, w int, h int, title string) voidptr {
	parent_view := macos.Id(parent)
	frame := flipped_rect(parent_view, x, y, w, h)
	button := C.macos_objc_msg_id_rect(macos.alloc('NSButton'), macos.sel('initWithFrame:'), frame)
	C.macos_objc_msg_void1(button, macos.sel('setTitle:'), macos.nsstring(title))
	C.macos_objc_msg_void_u64(button, macos.sel('setBezelStyle:'), ns_bezel_style_rounded)
	common_autoresizing(button)
	C.macos_objc_msg_void1(parent_view, macos.sel('addSubview:'), button)
	return button
}

fn native_update_button(handle voidptr, x int, y int, w int, h int, title string) {
	button := macos.Id(handle)
	update_frame_from_parent(button, x, y, w, h)
	C.macos_objc_msg_void1(button, macos.sel('setTitle:'), macos.nsstring(title))
	C.macos_objc_msg_void1(button, macos.sel('setNeedsDisplay:'), bool_to_ns(true))
}

fn native_button_set_callback(handle voidptr, callback fn (voidptr), v_button voidptr) {
	button := macos.Id(handle)
	target_class := ensure_button_target_class()
	target := macos.msg_id(macos.Id(target_class), 'new')
	C.macos_objc_set_ptr_ivar(target, c'callback_ptr', voidptr(callback))
	C.macos_objc_set_ptr_ivar(target, c'user_data_ptr', v_button)
	macos.set_associated_object(button, native_button_target_assoc_key(), target,
		macos.assoc_retain_nonatomic)
	C.macos_objc_msg_void1(button, macos.sel('setTarget:'), target)
	C.macos_objc_msg_void1(button, macos.sel('setAction:'), macos.sel('buttonClicked:'))
	macos.release(target)
}

fn native_button_set_enabled(handle voidptr, enabled bool) {
	C.macos_objc_msg_void_bool(macos.Id(handle), macos.sel('setEnabled:'), enabled)
}

fn native_set_enabled(handle voidptr, enabled bool) {
	if handle == unsafe { nil } {
		return
	}
	C.macos_objc_msg_void_bool(macos.Id(handle), macos.sel('setEnabled:'), enabled)
}

fn native_set_hidden(handle voidptr, hidden bool) {
	if handle == unsafe { nil } {
		return
	}
	C.macos_objc_msg_void_bool(macos.Id(handle), macos.sel('setHidden:'), hidden)
}

fn native_remove_view(handle voidptr) {
	view := macos.Id(handle)
	if view == unsafe { nil } {
		return
	}
	mut state := native_widgets_state()
	state.listbox_selected.delete(handle_key(handle))
	C.macos_objc_msg_void0(view, macos.sel('removeFromSuperview'))
	macos.release(view)
}

fn native_create_textfield(parent voidptr, x int, y int, w int, h int, placeholder string) voidptr {
	parent_view := macos.Id(parent)
	frame := flipped_rect(parent_view, x, y, w, h)
	textfield := C.macos_objc_msg_id_rect(macos.alloc('NSTextField'), macos.sel('initWithFrame:'),
		frame)
	if placeholder.len > 0 {
		cell := macos.msg_id(textfield, 'cell')
		C.macos_objc_msg_void1(cell, macos.sel('setPlaceholderString:'),
			macos.nsstring(placeholder))
	}
	C.macos_objc_msg_void_bool(textfield, macos.sel('setEditable:'), true)
	C.macos_objc_msg_void_bool(textfield, macos.sel('setSelectable:'), true)
	C.macos_objc_msg_void_bool(textfield, macos.sel('setBordered:'), true)
	C.macos_objc_msg_void_bool(textfield, macos.sel('setBezeled:'), true)
	C.macos_objc_msg_void_u64(textfield, macos.sel('setBezelStyle:'), ns_text_field_square_bezel)
	common_autoresizing(textfield)
	C.macos_objc_msg_void1(parent_view, macos.sel('addSubview:'), textfield)
	return textfield
}

fn native_update_textfield(handle voidptr, x int, y int, w int, h int, text string, placeholder string) {
	_ = text
	textfield := macos.Id(handle)
	update_frame_from_parent(textfield, x, y, w, h)
	if placeholder.len > 0 {
		cell := macos.msg_id(textfield, 'cell')
		C.macos_objc_msg_void1(cell, macos.sel('setPlaceholderString:'),
			macos.nsstring(placeholder))
	}
	C.macos_objc_msg_void1(textfield, macos.sel('setNeedsDisplay:'), bool_to_ns(true))
}

fn native_textfield_get_text(handle voidptr) string {
	string_value := macos.msg_id(macos.Id(handle), 'stringValue')
	return macos.utf8_string(string_value)
}

fn native_textfield_set_secure(handle voidptr, secure bool) {
	_ = handle
	_ = secure
}

fn native_create_checkbox(parent voidptr, x int, y int, w int, h int, title string, checked bool) voidptr {
	parent_view := macos.Id(parent)
	frame := flipped_rect(parent_view, x, y, w, h)
	checkbox := C.macos_objc_msg_id_rect(macos.alloc('NSButton'), macos.sel('initWithFrame:'),
		frame)
	C.macos_objc_msg_void_u64(checkbox, macos.sel('setButtonType:'), ns_button_type_switch)
	C.macos_objc_msg_void1(checkbox, macos.sel('setTitle:'), macos.nsstring(title))
	C.macos_objc_msg_void_i64(checkbox, macos.sel('setState:'), control_state(checked))
	common_autoresizing(checkbox)
	C.macos_objc_msg_void1(parent_view, macos.sel('addSubview:'), checkbox)
	return checkbox
}

fn native_update_checkbox(handle voidptr, x int, y int, w int, h int, title string, checked bool) {
	_ = checked
	checkbox := macos.Id(handle)
	update_frame_from_parent(checkbox, x, y, w, h)
	C.macos_objc_msg_void1(checkbox, macos.sel('setTitle:'), macos.nsstring(title))
	C.macos_objc_msg_void1(checkbox, macos.sel('setNeedsDisplay:'), bool_to_ns(true))
}

fn native_checkbox_is_checked(handle voidptr) bool {
	return macos.msg_i64(macos.Id(handle), 'state') == ns_control_state_on
}

fn native_create_radio_group(parent voidptr, x int, y int, w int, h int, values []string, selected int, title string) voidptr {
	parent_view := macos.Id(parent)
	frame := flipped_rect(parent_view, x, y, w, h)
	container := C.macos_objc_msg_id_rect(macos.alloc('NSView'), macos.sel('initWithFrame:'), frame)
	common_autoresizing(container)

	item_height := 20
	if title.len > 0 {
		title_frame := macos.rect(0, f64(values.len * item_height), f64(w), f64(item_height))
		label := C.macos_objc_msg_id_rect(macos.alloc('NSTextField'), macos.sel('initWithFrame:'),
			title_frame)
		C.macos_objc_msg_void1(label, macos.sel('setStringValue:'), macos.nsstring(title))
		C.macos_objc_msg_void_bool(label, macos.sel('setEditable:'), false)
		C.macos_objc_msg_void_bool(label, macos.sel('setSelectable:'), false)
		C.macos_objc_msg_void_bool(label, macos.sel('setBordered:'), false)
		C.macos_objc_msg_void_bool(label, macos.sel('setDrawsBackground:'), false)
		C.macos_objc_msg_void1(label, macos.sel('setBackgroundColor:'), clear_color())
		bold_font := C.macos_objc_msg_id_f64(macos.get_class('NSFont'),
			macos.sel('boldSystemFontOfSize:'), 12.0)
		C.macos_objc_msg_void1(label, macos.sel('setFont:'), bold_font)
		C.macos_objc_msg_void_i64(label, macos.sel('setTag:'), -1)
		C.macos_objc_msg_void1(container, macos.sel('addSubview:'), label)
	}

	for i, value in values {
		button_frame := macos.rect(0, f64((values.len - 1 - i) * item_height), f64(w),
			f64(item_height))
		radio := C.macos_objc_msg_id_rect(macos.alloc('NSButton'), macos.sel('initWithFrame:'),
			button_frame)
		C.macos_objc_msg_void_u64(radio, macos.sel('setButtonType:'), ns_button_type_radio)
		C.macos_objc_msg_void1(radio, macos.sel('setTitle:'), macos.nsstring(value))
		C.macos_objc_msg_void_i64(radio, macos.sel('setState:'), control_state(i == selected))
		C.macos_objc_msg_void_i64(radio, macos.sel('setTag:'), i)
		common_autoresizing(radio)
		C.macos_objc_msg_void1(container, macos.sel('addSubview:'), radio)
	}

	C.macos_objc_msg_void1(parent_view, macos.sel('addSubview:'), container)
	return container
}

fn native_update_radio_group(handle voidptr, x int, y int, w int, h int, selected int) {
	_ = selected
	container := macos.Id(handle)
	update_frame_from_parent(container, x, y, w, h)
	C.macos_objc_msg_void1(container, macos.sel('setNeedsDisplay:'), bool_to_ns(true))
}

fn native_radio_get_selected(handle voidptr) int {
	container := macos.Id(handle)
	subviews := macos.msg_id(container, 'subviews')
	count := int(macos.msg_u64(subviews, 'count'))
	for i in 0 .. count {
		subview := C.macos_objc_msg_id_u64(subviews, macos.sel('objectAtIndex:'), u64(i))
		tag := macos.msg_i64(subview, 'tag')
		if tag < 0 {
			continue
		}
		if macos.msg_i64(subview, 'state') == ns_control_state_on {
			return int(tag)
		}
	}
	return 0
}

fn native_create_progressbar(parent voidptr, x int, y int, w int, h int, min f64, max f64, val f64) voidptr {
	parent_view := macos.Id(parent)
	frame := flipped_rect(parent_view, x, y, w, h)
	progress := C.macos_objc_msg_id_rect(macos.alloc('NSProgressIndicator'),
		macos.sel('initWithFrame:'), frame)
	C.macos_objc_msg_void_u64(progress, macos.sel('setStyle:'), ns_progress_indicator_style_bar)
	C.macos_objc_msg_void_f64(progress, macos.sel('setMinValue:'), min)
	C.macos_objc_msg_void_f64(progress, macos.sel('setMaxValue:'), max)
	C.macos_objc_msg_void_f64(progress, macos.sel('setDoubleValue:'), val)
	C.macos_objc_msg_void_bool(progress, macos.sel('setIndeterminate:'), false)
	common_autoresizing(progress)
	C.macos_objc_msg_void1(parent_view, macos.sel('addSubview:'), progress)
	return progress
}

fn native_update_progressbar(handle voidptr, x int, y int, w int, h int, val f64) {
	progress := macos.Id(handle)
	update_frame_from_parent(progress, x, y, w, h)
	C.macos_objc_msg_void_f64(progress, macos.sel('setDoubleValue:'), val)
	C.macos_objc_msg_void1(progress, macos.sel('setNeedsDisplay:'), bool_to_ns(true))
}

fn native_create_label(parent voidptr, x int, y int, w int, h int, text string) voidptr {
	parent_view := macos.Id(parent)
	frame := flipped_rect(parent_view, x, y, w, h)
	label := C.macos_objc_msg_id_rect(macos.alloc('NSTextField'), macos.sel('initWithFrame:'),
		frame)
	C.macos_objc_msg_void1(label, macos.sel('setStringValue:'), macos.nsstring(text))
	C.macos_objc_msg_void_bool(label, macos.sel('setEditable:'), false)
	C.macos_objc_msg_void_bool(label, macos.sel('setSelectable:'), false)
	C.macos_objc_msg_void_bool(label, macos.sel('setBordered:'), false)
	C.macos_objc_msg_void_bool(label, macos.sel('setDrawsBackground:'), false)
	C.macos_objc_msg_void1(label, macos.sel('setBackgroundColor:'), clear_color())
	common_autoresizing(label)
	C.macos_objc_msg_void1(parent_view, macos.sel('addSubview:'), label)
	return label
}

fn native_update_label(handle voidptr, x int, y int, w int, h int, text string) {
	label := macos.Id(handle)
	update_frame_from_parent(label, x, y, w, h)
	C.macos_objc_msg_void1(label, macos.sel('setStringValue:'), macos.nsstring(text))
	C.macos_objc_msg_void1(label, macos.sel('setNeedsDisplay:'), bool_to_ns(true))
}

fn native_create_slider(parent voidptr, x int, y int, w int, h int, horizontal bool, min f64, max f64, val f64) voidptr {
	parent_view := macos.Id(parent)
	frame := flipped_rect(parent_view, x, y, w, h)
	slider := C.macos_objc_msg_id_rect(macos.alloc('NSSlider'), macos.sel('initWithFrame:'), frame)
	C.macos_objc_msg_void_f64(slider, macos.sel('setMinValue:'), min)
	C.macos_objc_msg_void_f64(slider, macos.sel('setMaxValue:'), max)
	C.macos_objc_msg_void_f64(slider, macos.sel('setDoubleValue:'), val)
	if !horizontal {
		C.macos_objc_msg_void_bool(slider, macos.sel('setVertical:'), true)
	}
	common_autoresizing(slider)
	C.macos_objc_msg_void1(parent_view, macos.sel('addSubview:'), slider)
	return slider
}

fn native_update_slider(handle voidptr, x int, y int, w int, h int, val f64) {
	_ = val
	slider := macos.Id(handle)
	update_frame_from_parent(slider, x, y, w, h)
	C.macos_objc_msg_void1(slider, macos.sel('setNeedsDisplay:'), bool_to_ns(true))
}

fn native_slider_get_value(handle voidptr) f64 {
	return macos.msg_f64(macos.Id(handle), 'doubleValue')
}

fn native_create_dropdown(parent voidptr, x int, y int, w int, h int, items []string, selected int) voidptr {
	parent_view := macos.Id(parent)
	frame := flipped_rect(parent_view, x, y, w, h)
	dropdown := C.macos_objc_msg_id_rect_bool(macos.alloc('NSPopUpButton'),
		macos.sel('initWithFrame:pullsDown:'), frame, false)
	for item in items {
		C.macos_objc_msg_void1(dropdown, macos.sel('addItemWithTitle:'), macos.nsstring(item))
	}
	if selected >= 0 && selected < items.len {
		C.macos_objc_msg_void_u64(dropdown, macos.sel('selectItemAtIndex:'), u64(selected))
	}
	common_autoresizing(dropdown)
	C.macos_objc_msg_void1(parent_view, macos.sel('addSubview:'), dropdown)
	return dropdown
}

fn native_update_dropdown(handle voidptr, x int, y int, w int, h int, selected int) {
	_ = selected
	dropdown := macos.Id(handle)
	update_frame_from_parent(dropdown, x, y, w, h)
	C.macos_objc_msg_void1(dropdown, macos.sel('setNeedsDisplay:'), bool_to_ns(true))
}

fn native_dropdown_get_selected(handle voidptr) int {
	return int(macos.msg_i64(macos.Id(handle), 'indexOfSelectedItem'))
}

fn native_create_listbox(parent voidptr, x int, y int, w int, h int, items []string, selected int) voidptr {
	parent_view := macos.Id(parent)
	frame := flipped_rect(parent_view, x, y, w, h)
	scroll_view := C.macos_objc_msg_id_rect(macos.alloc('NSScrollView'),
		macos.sel('initWithFrame:'), frame)
	C.macos_objc_msg_void_bool(scroll_view, macos.sel('setHasVerticalScroller:'), true)
	C.macos_objc_msg_void_u64(scroll_view, macos.sel('setBorderType:'), ns_bezel_border)
	common_autoresizing(scroll_view)

	item_height := 20
	doc_view_frame := macos.rect(0, 0, f64(w), f64(items.len * item_height))
	doc_view := C.macos_objc_msg_id_rect(macos.alloc('NSView'), macos.sel('initWithFrame:'),
		doc_view_frame)

	for i, item in items {
		item_frame := macos.rect(0, f64((items.len - 1 - i) * item_height), f64(w - 15),
			f64(item_height))
		label := C.macos_objc_msg_id_rect(macos.alloc('NSTextField'), macos.sel('initWithFrame:'),
			item_frame)
		C.macos_objc_msg_void1(label, macos.sel('setStringValue:'), macos.nsstring(item))
		C.macos_objc_msg_void_bool(label, macos.sel('setEditable:'), false)
		C.macos_objc_msg_void_bool(label, macos.sel('setSelectable:'), false)
		C.macos_objc_msg_void_bool(label, macos.sel('setBordered:'), false)
		C.macos_objc_msg_void_bool(label, macos.sel('setDrawsBackground:'), i == selected)
		C.macos_objc_msg_void1(label, macos.sel('setBackgroundColor:'), if i == selected {
			selected_text_background_color()
		} else {
			clear_color()
		})
		C.macos_objc_msg_void_i64(label, macos.sel('setTag:'), i)
		C.macos_objc_msg_void1(doc_view, macos.sel('addSubview:'), label)
	}

	C.macos_objc_msg_void1(scroll_view, macos.sel('setDocumentView:'), doc_view)
	C.macos_objc_msg_void1(parent_view, macos.sel('addSubview:'), scroll_view)
	native_widgets_state().listbox_selected[handle_key(&scroll_view)] = selected
	return scroll_view
}

fn native_update_listbox(handle voidptr, x int, y int, w int, h int, selected int) {
	_ = selected
	scroll_view := macos.Id(handle)
	update_frame_from_parent(scroll_view, x, y, w, h)
	C.macos_objc_msg_void1(scroll_view, macos.sel('setNeedsDisplay:'), bool_to_ns(true))
}

fn native_listbox_get_selected(handle voidptr) int {
	state := native_widgets_state()
	return state.listbox_selected[handle_key(handle)] or { -1 }
}

fn native_create_switch(parent voidptr, x int, y int, w int, h int, open bool) voidptr {
	parent_view := macos.Id(parent)
	frame := flipped_rect(parent_view, x, y, w, h)
	sw := C.macos_objc_msg_id_rect(macos.alloc('NSButton'), macos.sel('initWithFrame:'), frame)
	C.macos_objc_msg_void_u64(sw, macos.sel('setButtonType:'), ns_button_type_switch)
	C.macos_objc_msg_void1(sw, macos.sel('setTitle:'), macos.nsstring(''))
	C.macos_objc_msg_void_i64(sw, macos.sel('setState:'), control_state(open))
	common_autoresizing(sw)
	C.macos_objc_msg_void1(parent_view, macos.sel('addSubview:'), sw)
	return sw
}

fn native_update_switch(handle voidptr, x int, y int, w int, h int, open bool) {
	_ = open
	sw := macos.Id(handle)
	update_frame_from_parent(sw, x, y, w, h)
	C.macos_objc_msg_void1(sw, macos.sel('setNeedsDisplay:'), bool_to_ns(true))
}

fn native_switch_is_open(handle voidptr) bool {
	return macos.msg_i64(macos.Id(handle), 'state') == ns_control_state_on
}

fn native_create_picture(parent voidptr, x int, y int, w int, h int, path string) voidptr {
	parent_view := macos.Id(parent)
	frame := flipped_rect(parent_view, x, y, w, h)
	image_view := C.macos_objc_msg_id_rect(macos.alloc('NSImageView'), macos.sel('initWithFrame:'),
		frame)
	if path.len > 0 {
		image := C.macos_objc_msg_id1(macos.alloc('NSImage'), macos.sel('initWithContentsOfFile:'),
			macos.nsstring(path))
		if image != unsafe { nil } {
			C.macos_objc_msg_void1(image_view, macos.sel('setImage:'), image)
		}
	}
	C.macos_objc_msg_void_u64(image_view, macos.sel('setImageScaling:'),
		ns_image_scale_proportionally_up_or_down)
	common_autoresizing(image_view)
	C.macos_objc_msg_void1(parent_view, macos.sel('addSubview:'), image_view)
	return image_view
}

fn native_update_picture(handle voidptr, x int, y int, w int, h int) {
	image_view := macos.Id(handle)
	update_frame_from_parent(image_view, x, y, w, h)
	C.macos_objc_msg_void1(image_view, macos.sel('setNeedsDisplay:'), bool_to_ns(true))
}

fn native_create_menu(parent voidptr, x int, y int, w int, h int, items []string) voidptr {
	parent_view := macos.Id(parent)
	frame := flipped_rect(parent_view, x, y, w, h)
	container := C.macos_objc_msg_id_rect(macos.alloc('NSView'), macos.sel('initWithFrame:'), frame)
	common_autoresizing(container)

	item_width := if items.len > 0 { w / items.len } else { w }
	for i, item in items {
		button_frame := macos.rect(f64(i * item_width), 0, f64(item_width), f64(h))
		button := C.macos_objc_msg_id_rect(macos.alloc('NSButton'), macos.sel('initWithFrame:'),
			button_frame)
		C.macos_objc_msg_void1(button, macos.sel('setTitle:'), macos.nsstring(item))
		C.macos_objc_msg_void_u64(button, macos.sel('setBezelStyle:'), ns_bezel_style_rounded)
		C.macos_objc_msg_void_i64(button, macos.sel('setTag:'), i)
		C.macos_objc_msg_void1(container, macos.sel('addSubview:'), button)
	}

	C.macos_objc_msg_void1(parent_view, macos.sel('addSubview:'), container)
	return container
}

pub fn (mut nw NativeWidgets) init_parent(window_handle voidptr) {
	nw.parent_handle = native_get_content_view(window_handle)
}

// set_enabled mirrors the V model's disabled flag onto the native control.
pub fn (nw &NativeWidgets) set_enabled(nwidget &NativeWidget, enabled bool) {
	native_set_enabled(nwidget.handle, enabled)
}

// set_visible mirrors the V model's hidden flag onto the native control.
pub fn (nw &NativeWidgets) set_visible(nwidget &NativeWidget, visible bool) {
	native_set_hidden(nwidget.handle, !visible)
}

pub fn (mut nw NativeWidgets) create_button(x int, y int, w int, h int, title string) NativeWidget {
	return NativeWidget{
		handle: native_create_button(nw.parent_handle, x, y, w, h, title)
	}
}

pub fn (nw &NativeWidgets) button_set_callback(nwidget &NativeWidget, callback fn (voidptr), v_button voidptr) {
	native_button_set_callback(nwidget.handle, callback, v_button)
}

pub fn (nw &NativeWidgets) update_button(nwidget &NativeWidget, x int, y int, w int, h int, title string) {
	native_update_button(nwidget.handle, x, y, w, h, title)
}

pub fn (mut nw NativeWidgets) create_textfield(x int, y int, w int, h int, placeholder string) NativeWidget {
	return NativeWidget{
		handle: native_create_textfield(nw.parent_handle, x, y, w, h, placeholder)
	}
}

pub fn (nw &NativeWidgets) update_textfield(nwidget &NativeWidget, x int, y int, w int, h int, text string, placeholder string) {
	native_update_textfield(nwidget.handle, x, y, w, h, text, placeholder)
}

pub fn (nw &NativeWidgets) textfield_set_secure(nwidget &NativeWidget, secure bool) {
	native_textfield_set_secure(nwidget.handle, secure)
}

pub fn (mut nw NativeWidgets) create_checkbox(x int, y int, w int, h int, title string, checked bool) NativeWidget {
	return NativeWidget{
		handle: native_create_checkbox(nw.parent_handle, x, y, w, h, title, checked)
	}
}

pub fn (nw &NativeWidgets) update_checkbox(nwidget &NativeWidget, x int, y int, w int, h int, title string, checked bool) {
	native_update_checkbox(nwidget.handle, x, y, w, h, title, checked)
}

pub fn (mut nw NativeWidgets) create_radio_group(x int, y int, w int, h int, values []string, selected int, title string) NativeWidget {
	return NativeWidget{
		handle: native_create_radio_group(nw.parent_handle, x, y, w, h, values, selected, title)
	}
}

pub fn (nw &NativeWidgets) update_radio_group(nwidget &NativeWidget, x int, y int, w int, h int, selected int) {
	native_update_radio_group(nwidget.handle, x, y, w, h, selected)
}

pub fn (mut nw NativeWidgets) create_progressbar(x int, y int, w int, h int, min f64, max f64, val f64) NativeWidget {
	return NativeWidget{
		handle: native_create_progressbar(nw.parent_handle, x, y, w, h, min, max, val)
	}
}

pub fn (nw &NativeWidgets) update_progressbar(nwidget &NativeWidget, x int, y int, w int, h int, val f64) {
	native_update_progressbar(nwidget.handle, x, y, w, h, val)
}

pub fn (mut nw NativeWidgets) create_label(x int, y int, w int, h int, text string) NativeWidget {
	return NativeWidget{
		handle: native_create_label(nw.parent_handle, x, y, w, h, text)
	}
}

pub fn (nw &NativeWidgets) update_label(nwidget &NativeWidget, x int, y int, w int, h int, text string) {
	native_update_label(nwidget.handle, x, y, w, h, text)
}

pub fn (mut nw NativeWidgets) create_slider(x int, y int, w int, h int, orientation Orientation, min f64, max f64, val f64) NativeWidget {
	return NativeWidget{
		handle: native_create_slider(nw.parent_handle, x, y, w, h, orientation == .horizontal, min,
			max, val)
	}
}

pub fn (nw &NativeWidgets) update_slider(nwidget &NativeWidget, x int, y int, w int, h int, val f64) {
	native_update_slider(nwidget.handle, x, y, w, h, val)
}

pub fn (mut nw NativeWidgets) create_dropdown(x int, y int, w int, h int, items []string, selected int) NativeWidget {
	return NativeWidget{
		handle: native_create_dropdown(nw.parent_handle, x, y, w, h, items, selected)
	}
}

pub fn (nw &NativeWidgets) update_dropdown(nwidget &NativeWidget, x int, y int, w int, h int, selected int) {
	native_update_dropdown(nwidget.handle, x, y, w, h, selected)
}

pub fn (mut nw NativeWidgets) create_listbox(x int, y int, w int, h int, items []string, selected int) NativeWidget {
	return NativeWidget{
		handle: native_create_listbox(nw.parent_handle, x, y, w, h, items, selected)
	}
}

pub fn (nw &NativeWidgets) update_listbox(nwidget &NativeWidget, x int, y int, w int, h int, selected int) {
	native_update_listbox(nwidget.handle, x, y, w, h, selected)
}

pub fn (mut nw NativeWidgets) create_switch(x int, y int, w int, h int, open bool) NativeWidget {
	return NativeWidget{
		handle: native_create_switch(nw.parent_handle, x, y, w, h, open)
	}
}

pub fn (nw &NativeWidgets) update_switch(nwidget &NativeWidget, x int, y int, w int, h int, open bool) {
	native_update_switch(nwidget.handle, x, y, w, h, open)
}

pub fn (mut nw NativeWidgets) create_picture(x int, y int, w int, h int, path string) NativeWidget {
	return NativeWidget{
		handle: native_create_picture(nw.parent_handle, x, y, w, h, path)
	}
}

pub fn (nw &NativeWidgets) update_picture(nwidget &NativeWidget, x int, y int, w int, h int) {
	native_update_picture(nwidget.handle, x, y, w, h)
}

pub fn (mut nw NativeWidgets) create_menu(x int, y int, w int, h int, items []string) NativeWidget {
	return NativeWidget{
		handle: native_create_menu(nw.parent_handle, x, y, w, h, items)
	}
}

pub fn (nw &NativeWidgets) textfield_get_text(nwidget &NativeWidget) string {
	return native_textfield_get_text(nwidget.handle)
}

pub fn (nw &NativeWidgets) checkbox_is_checked(nwidget &NativeWidget) bool {
	return native_checkbox_is_checked(nwidget.handle)
}

pub fn (nw &NativeWidgets) radio_get_selected(nwidget &NativeWidget) int {
	return native_radio_get_selected(nwidget.handle)
}

pub fn (nw &NativeWidgets) slider_get_value(nwidget &NativeWidget) f64 {
	return native_slider_get_value(nwidget.handle)
}

pub fn (nw &NativeWidgets) dropdown_get_selected(nwidget &NativeWidget) int {
	return native_dropdown_get_selected(nwidget.handle)
}

pub fn (nw &NativeWidgets) listbox_get_selected(nwidget &NativeWidget) int {
	return native_listbox_get_selected(nwidget.handle)
}

pub fn (nw &NativeWidgets) switch_is_open(nwidget &NativeWidget) bool {
	return native_switch_is_open(nwidget.handle)
}

pub fn (nw &NativeWidgets) remove(nwidget &NativeWidget) {
	native_remove_view(nwidget.handle)
}
