module component

import ui
import gx
import os

pub type MenuFileFn = fn (&MenuFileComponent)

@[heap]
pub struct MenuFileComponent {
pub mut:
	id              string
	layout          &ui.Stack = unsafe { nil }
	hidden_files    bool
	file            string
	folder_to_open  string
	item_selected   string
	on_save         MenuFileFn = unsafe { MenuFileFn(0) }
	on_new          MenuFileFn = unsafe { MenuFileFn(0) }
	on_file_changed MenuFileFn = unsafe { MenuFileFn(0) }
}

@[params]
pub struct MenuFileParams {
pub:
	id              string
	hidden_files    bool
	dirs            []string
	on_save         MenuFileFn = unsafe { MenuFileFn(0) }
	on_new          MenuFileFn = unsafe { MenuFileFn(0) }
	on_file_changed MenuFileFn = unsafe { MenuFileFn(0) }
	bg_color        gx.Color   = ui.color_solaris
}

// TODO: documentation
pub fn menufile_stack(p MenuFileParams) &ui.Stack {
	btn_newfile := ui.button(
		id:           ui.component_id(p.id, 'btn_newfile')
		tooltip:      'New File'
		tooltip_side: .right
		text:         'New'
		on_click:     btn_new_click
		radius:       .3
		z_index:      10
	)
	btn_openfolder := ui.button(
		id:           ui.component_id(p.id, 'btn_openfolder')
		tooltip:      'Open Folder'
		tooltip_side: .right
		text:         'Open'
		on_click:     btn_open_click
		radius:       .3
		z_index:      10
	)
	btn_savefile := ui.button(
		id:           ui.component_id(p.id, 'btn_savefile')
		tooltip:      'Save File'
		tooltip_side: .right
		text:         'Save'
		on_click:     btn_save_click
		radius:       .3
		z_index:      10
	)

	mut layout := ui.column(
		id:       ui.component_id(p.id, 'layout')
		heights:  [40.0, 30.0, ui.stretch]
		spacing:  5
		margin_:  3
		bg_color: gx.black
		children: [
			ui.row(
				widths:   ui.stretch
				heights:  30.0
				margin:   ui.Margin{5, 10, 5, 10}
				spacing:  10
				bg_color: gx.black
				children: [btn_newfile, btn_openfolder, btn_savefile]
			),
			hideable_stack(
				id:     ui.component_id(p.id, 'htb')
				layout: ui.row(
					id:       ui.component_id(p.id, 'htbl')
					margin_:  3
					heights:  24.0
					spacing:  3
					widths:   [ui.stretch, 24]
					children: [
						ui.textbox(
							id:      ui.component_id(p.id, 'tb')
							z_index: 10
						),
						ui.button(
							id:       ui.component_id(p.id, 'tb_new_ok')
							text:     'Ok'
							z_index:  10
							radius:   5
							on_click: btn_new_ok
						),
					]
				)
			),
			ui.column(
				id:         ui.component_id(p.id, 'tvcol')
				scrollview: true
				heights:    ui.compact
				bg_color:   p.bg_color
				children:   [
					dirtreeview_stack(
						id:           ui.component_id(p.id, 'dtv')
						trees:        p.dirs
						hidden_files: p.hidden_files
						on_click:     treeview_onclick
					),
				]
			),
		]
	)
	mf := &MenuFileComponent{
		id:              p.id
		layout:          layout
		on_save:         p.on_save
		on_new:          p.on_new
		on_file_changed: p.on_file_changed
	}
	ui.component_connect(mf, layout, btn_savefile)
	layout.on_init = menufile_init
	return layout
}

// component access
pub fn menufile_component(w ui.ComponentChild) &MenuFileComponent {
	return unsafe { &MenuFileComponent(w.component) }
}

// TODO: documentation
pub fn menufile_component_from_id(w ui.Window, id string) &MenuFileComponent {
	return menufile_component(w.get_or_panic[ui.Stack](ui.component_id(id, 'layout')))
}

// TODO: documentation
pub fn (mf &MenuFileComponent) treeview_component() &TreeViewComponent {
	return treeview_component_from_id(mf.layout.ui.window, ui.component_id(mf.id, 'dtv'))
}

// Init

// TODO: documentation
pub fn menufile_init(layout &ui.Stack) {
	mut window := layout.ui.window
	// println('fb.id: ${ui.component_id(ui.component_parent_id(layout.id), 'fb')}')
	filebrowser_subwindow_add(mut window,
		id:              ui.component_id_from(layout.id, 'fb')
		folder_only:     true
		width:           400
		height:          300
		x:               50
		y:               50
		bg_color:        ui.color_solaris_transparent
		on_click_ok:     btn_open_ok
		on_click_cancel: btn_open_cancel
	)
}

// treeview
fn treeview_onclick(c &ui.CanvasLayout, mut tv TreeViewComponent) {
	win := c.ui.window
	mut mf := menufile_component_from_id(win, ui.component_parent_id(tv.id))
	mf.item_selected = c.id
	mf.file = tv.full_title(mf.item_selected)
	if mf.on_file_changed != unsafe { MenuFileFn(0) } {
		mf.on_file_changed(mf)
	}
}

// New
fn btn_new_click(b &ui.Button) {
	// println('new')
	htb_id := ui.component_id_from(b.id, 'htb')
	mut h := hideable_component_from_id(b.ui.window, htb_id)
	h.toggle()
}

fn btn_new_ok(b &ui.Button) {
	// // println('ok new')
	mf_id := ui.component_parent_id(b.id)
	tb := b.ui.window.get_or_panic[ui.TextBox](ui.component_id(mf_id, 'tb'))
	mut h := hideable_component_from_id(b.ui.window, ui.component_id(mf_id, 'htb'))
	mut dtv := treeview_component_from_id(b.ui.window, ui.component_id(mf_id, 'dtv'))
	if dtv.sel_id != '' {
		mut mf := menufile_component_from_id(b.ui.window, mf_id)
		sel_path := dtv.selected_full_title()
		mf.folder_to_open = if dtv.types[dtv.sel_id] == 'root' { sel_path } else { os.dir(sel_path) }
		mf.file = os.join_path(mf.folder_to_open, *tb.text)
		if mf.on_new != unsafe { MenuFileFn(0) } {
			mf.on_new(mf)
		}
		dtv.open_dir(mf.folder_to_open)
	}
	h.hide()
}

// Open folder
fn btn_open_click(b &ui.Button) {
	// // println('open')
	filebrowser_subwindow_visible(b.ui.window, ui.component_id_from(b.id, 'fb'))
}

fn btn_open_ok(b &ui.Button) {
	// println('ok')
	filebrowser_subwindow_close(b.ui.window, ui.component_parent_id(b.id))
	fb := filebrowser_component(b)
	mut dtv := treeview_component_from_id(b.ui.window, ui.component_id_from_by(b.id, 2,
		'dtv'))
	mut mf := menufile_component_from_id(b.ui.window, ui.component_parent_id_by(b.id,
		2))
	mf.folder_to_open = fb.selected_full_title()
	dtv.open_dir(mf.folder_to_open)
}

fn btn_open_cancel(b &ui.Button) {
	// println('cancel open')
	filebrowser_subwindow_close(b.ui.window, ui.component_parent_id(b.id))
	mut mf := menufile_component_from_id(b.ui.window, ui.component_parent_id_by(b.id,
		2))
	mf.folder_to_open = ''
}

// Save file
fn btn_save_click(b &ui.Button) {
	mf := menufile_component_from_id(b.ui.window, ui.component_parent_id(b.id))
	if mf.on_save != unsafe { MenuFileFn(0) } {
		mf.on_save(mf)
	}
	b.ui.window.root_layout.unfocus_all()
}
