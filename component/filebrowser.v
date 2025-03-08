module component

import gx
import ui
import os

@[heap]
pub struct FileBrowserComponent {
pub mut:
	layout     &ui.Stack          = unsafe { nil }
	btn_cancel &ui.Button         = unsafe { nil }
	btn_ok     &ui.Button         = unsafe { nil }
	tv         &TreeViewComponent = unsafe { nil }
	dir        string
}

@[params]
pub struct FileBrowserParams {
pub:
	id              string
	dirs            []string = [os.expand_tilde_to_home('~'), '/']
	text_ok         string   = 'Ok'
	text_cancel     string   = 'Cancel'
	height          int      = int(ui.compact)
	width           int      = int(ui.compact)
	z_index         int
	folder_only     bool
	filter_types    []string
	with_fpath      bool
	hidden          bool
	bg_color        gx.Color    = gx.red // gx.hex(0xfcf4e4ff)
	on_click_ok     ui.ButtonFn = unsafe { ui.ButtonFn(0) }
	on_click_cancel ui.ButtonFn = unsafe { ui.ButtonFn(0) }
}

// TODO: documentation
pub fn filebrowser_stack(p FileBrowserParams) &ui.Stack {
	btn_cancel := ui.button(
		id:       ui.component_id(p.id, 'btn_cancel')
		text:     p.text_cancel
		radius:   5
		z_index:  100
		on_click: p.on_click_cancel
	)
	btn_ok := ui.button(
		id:       ui.component_id(p.id, 'btn_ok')
		text:     p.text_ok
		radius:   5
		z_index:  100
		on_click: p.on_click_ok
	)
	tv_layout := dirtreeview_stack(
		id:           ui.component_id(p.id, 'tvd')
		trees:        p.dirs
		folder_only:  p.folder_only
		filter_types: p.filter_types
		bg_color:     ui.transparent
	)
	mut children := [
		ui.Widget(ui.column(
			id:         ui.component_id(p.id, 'tvd_col')
			scrollview: true
			// heights: ui.compact
			bg_color: p.bg_color
			children: [tv_layout]
		)),
		ui.Widget(ui.row(
			id:       ui.component_id(p.id, 'btns_row')
			widths:   [ui.stretch, 50, ui.stretch, 50, ui.stretch]
			heights:  30.0
			margin_:  5
			bg_color: gx.black
			children: [ui.spacing(), btn_cancel, ui.spacing(), btn_ok, ui.spacing()]
		)),
	]
	if p.with_fpath {
		tb := ui.textbox(id: ui.component_id(p.id, 'tb'), placeholder: 'File path...')
		children.insert(1, ui.Widget(tb))
	}
	mut layout := ui.column(
		id:       ui.component_id(p.id, 'layout')
		width:    p.width
		height:   p.height
		heights:  if p.with_fpath { [ui.stretch, 30, 40] } else { [ui.stretch, 40] }
		children: children
	)
	tv := treeview_component(tv_layout)
	mut fb := &FileBrowserComponent{
		layout:     layout
		btn_ok:     btn_ok
		btn_cancel: btn_cancel
		tv:         tv
	}
	ui.component_connect(fb, layout, btn_ok, btn_cancel)
	return layout
}

// component access
pub fn filebrowser_component(w ui.ComponentChild) &FileBrowserComponent {
	return unsafe { &FileBrowserComponent(w.component) }
}

// TODO: documentation
pub fn filebrowser_component_from_id(w ui.Window, id string) &FileBrowserComponent {
	return filebrowser_component(w.get_or_panic[ui.Stack](ui.component_id(id, 'layout')))
}

// TODO: documentation
pub fn (fb &FileBrowserComponent) selected_full_title() string {
	tv := fb.tv
	return tv.selected_full_title()
}
