module component

import gx
import ui
import os

[heap]
struct FileBrowser {
pub mut:
	layout     &ui.Stack
	btn_cancel &ui.Button
	btn_ok     &ui.Button
	tv         &TreeView
	dir        string
	// To become a component of a parent component
	component voidptr
}

[params]
pub struct FileBrowserParams {
	id              string
	dir             string = os.expand_tilde_to_home('~')
	text_ok         string = 'Ok'
	text_cancel     string = 'Cancel'
	height          int
	width           int
	z_index         int
	bg_color        gx.Color = gx.white
	on_click_ok     ui.ButtonClickFn
	on_click_cancel ui.ButtonClickFn
}

pub fn filebrowser(p FileBrowserParams) &ui.Stack {
	btn_cancel := ui.button(
		id: '${p.id}_btn_cancel'
		text: p.text_cancel
		radius: 5
		onclick: p.on_click_cancel
	)
	btn_ok := ui.button(
		id: '${p.id}_btn_ok'
		text: p.text_ok
		radius: 5
		onclick: p.on_click_ok
	)
	tv_layout := treeview_dir(
		id: '${p.id}_tvd'
		trees: [p.dir, '/']
	)
	mut layout := ui.column(
		heights: [ui.stretch, 40]
		children: [
			ui.column(
				id: '${p.id}_tvd_col'
				scrollview: true
				heights: ui.compact
				bg_color: gx.hex(0xfcf4e4ff)
				children: [tv_layout]
			),
			ui.row(
				id: '${p.id}_btns_row'
				widths: [ui.stretch, 50, ui.stretch, 50, ui.stretch]
				heights: 30.0
				margin_: 5
				bg_color: gx.black
				children: [ui.spacing(color: p.bg_color), btn_cancel, ui.spacing(color: p.bg_color),
					btn_ok, ui.spacing(color: p.bg_color)]
			),
		]
	)
	tv := component_treeview(tv_layout)
	mut fb := &FileBrowser{
		layout: layout
		btn_ok: btn_ok
		btn_cancel: btn_cancel
		tv: tv
	}
	ui.component_connect(fb, layout, btn_ok, btn_cancel)
	return layout
}

// component access
pub fn component_filebrowser(w ui.ComponentChild) &FileBrowser {
	return &FileBrowser(w.component)
}
