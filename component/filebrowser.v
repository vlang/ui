module component

import gx
import ui
import os

[heap]
struct FileBrowserComponent {
pub mut:
	layout     &ui.Stack
	btn_cancel &ui.Button
	btn_ok     &ui.Button
	tv         &TreeViewComponent
	dir        string
}

[params]
pub struct FileBrowserParams {
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
	bg_color        gx.Color = gx.hex(0xfcf4e4ff)
	on_click_ok     ui.ButtonClickFn
	on_click_cancel ui.ButtonClickFn
}

pub fn filebrowser_stack(p FileBrowserParams) &ui.Stack {
	btn_cancel := ui.button(
		id: '${p.id}_btn_cancel'
		text: p.text_cancel
		radius: 5
		z_index: 100
		onclick: p.on_click_cancel
	)
	btn_ok := ui.button(
		id: '${p.id}_btn_ok'
		text: p.text_ok
		radius: 5
		z_index: 100
		onclick: p.on_click_ok
	)
	tv_layout := dirtreeview_stack(
		id: '${p.id}_tvd'
		trees: p.dirs
		folder_only: p.folder_only
		filter_types: p.filter_types
		bg_color: ui.no_color
	)
	mut children := [
		ui.Widget(ui.column(
			id: '${p.id}_tvd_col'
			scrollview: true
			// heights: ui.compact
			bg_color: p.bg_color
			children: [tv_layout]
		)),
		ui.Widget(ui.row(
			id: '${p.id}_btns_row'
			widths: [ui.stretch, 50, ui.stretch, 50, ui.stretch]
			heights: 30.0
			margin_: 5
			bg_color: gx.black
			children: [ui.spacing(), btn_cancel, ui.spacing(), btn_ok, ui.spacing()]
		)),
	]
	if p.with_fpath {
		tb := ui.textbox(id: '${p.id}_tb', placeholder: 'File path...')
		children.insert(1, ui.Widget(tb))
	}
	mut layout := ui.column(
		id: ui.component_id(p.id, 'layout')
		width: p.width
		height: p.height
		heights: if p.with_fpath { [ui.stretch, 30, 40] } else { [ui.stretch, 40] }
		children: children
	)
	tv := treeview_component(tv_layout)
	mut fb := &FileBrowserComponent{
		layout: layout
		btn_ok: btn_ok
		btn_cancel: btn_cancel
		tv: tv
	}
	ui.component_connect(fb, layout, btn_ok, btn_cancel)
	return layout
}

// component access
pub fn filebrowser_component(w ui.ComponentChild) &FileBrowserComponent {
	return &FileBrowserComponent(w.component)
}

pub fn filebrowser_component_from_id(w ui.Window, id string) &FileBrowserComponent {
	return filebrowser_component(w.stack(ui.component_id(id, 'layout')))
}

pub fn (fb &FileBrowserComponent) selected_full_title() string {
	tv := fb.tv
	return tv.selected_full_title()
}
