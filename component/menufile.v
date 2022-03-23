module component

import ui
import gx

pub type MenuFileFn = fn (&MenuFileComponent)

[heap]
struct MenuFileComponent {
	layout          &ui.Stack
	hidden_files    bool
	on_save         MenuFileFn
	on_new          MenuFileFn
	on_file_changed MenuFileFn
}

[params]
pub struct MenuFileParams {
	id              string
	hidden_files    bool
	dirs            []string
	on_save         MenuFileFn
	on_new          MenuFileFn
	on_file_changed MenuFileFn
}

pub fn menufile_stack(p MenuFileParams) &ui.Stack {
	btn_newfile := ui.button(
		id: ui.component_id(p.id, 'btn_newfile')
		tooltip: 'New File'
		tooltip_side: .right
		text: 'New'
		onclick: btn_new_click
		radius: .3
		z_index: 10
	)
	btn_openfolder := ui.button(
		id: ui.component_id(p.id, 'btn_openfolder')
		tooltip: 'Open Folder'
		tooltip_side: .right
		text: 'Open'
		onclick: btn_open_click
		radius: .3
		z_index: 10
	)
	btn_savefile := ui.button(
		id: ui.component_id(p.id, 'btn_savefile')
		tooltip: 'Save File'
		tooltip_side: .right
		text: 'Save'
		onclick: btn_save_click
		radius: .3
		z_index: 10
	)

	layout := ui.column(
		id: ui.component_id(p.id, 'layout')
		heights: [40.0, 30.0, ui.stretch]
		spacing: 5
		margin_: 3
		bg_color: gx.black
		children: [
			ui.row(
				widths: ui.stretch
				heights: 30.0
				margin: ui.Margin{5, 10, 5, 10}
				spacing: 10
				bg_color: gx.black
				children: [btn_newfile, btn_openfolder, btn_savefile]
			),
			hideable_stack(
				id: ui.component_id(p.id, 'htb')
				layout: ui.row(
					id: ui.component_id(p.id, 'htbl')
					margin_: 3
					heights: 24.0
					spacing: 3
					widths: [ui.stretch, 24]
					children: [
						ui.textbox(
						id: ui.component_id(p.id, 'tb')
						z_index: 10
					),
						ui.button(
							id: ui.component_id(p.id, 'tb_ok')
							text: 'Ok'
							z_index: 10
							radius: 5
							onclick: btn_new_ok
						)]
				)
			),
			ui.column(
				id: ui.component_id(p.id, 'tvcol')
				scrollview: true
				heights: ui.compact
				bg_color: gx.hex(0xfcf4e4ff)
				children: [
					dirtreeview_stack(
					id: ui.component_id(p.id, 'dtv')
					trees: p.dirs
					hidden_files: p.hidden_files
					///on_click: treeview_onclick
				)]
			),
		]
	)
	mf := &MenuFileComponent{
		layout: layout
		on_save: p.on_save
		on_new: p.on_new
		on_file_changed: p.on_file_changed
	}
	ui.component_connect(mf, layout, btn_savefile)
	return layout
}

// component access
pub fn menufile_component(w ui.ComponentChild) &MenuFileComponent {
	return &MenuFileComponent(w.component)
}

pub fn menufile_component_from_id(w ui.Window, id string) &MenuFileComponent {
	return menufile_component(w.stack(ui.component_id(id, 'layout')))
}

// Init

pub fn menufile_init(layout &ui.Stack) {
	mut window := layout.ui.window
	filebrowser_subwindow_add(mut window,
		id: ui.component_id(ui.component_parent_id(layout.id), 'fb')
		folder_only: true
		width: 400
		height: 300
		x: 50
		y: 50
		bg_color: gx.white
		on_click_ok: btn_open_ok
		on_click_cancel: btn_open_cancel
	)
}

// treeview
fn treeview_onclick(c &ui.CanvasLayout, mut tv TreeViewComponent) {
	selected := c.id
	// mut app := &App(c.ui.window.state)
	// app.file = tv.full_title(selected)
	// app.text = os.read_file(app.file) or { '' }

	mf := menufile_component_from_id(c.ui.window, ui.component_parent_id(tv.id))
	if mf.on_file_changed != MenuFileFn(0) {
		mf.on_file_changed(mf)
	}

	// if os.file_ext(app.file) == '.png' {
	// 	app.window.set_title('V UI Png Edit: ${tv.titles[selected]}')
	// 	mut rv := uic.rasterview_component_from_id(app.window, 'rv')
	// 	rv.load(app.file)
	// 	colors := rv.top_colors()
	// 	// println("$app.file")
	// 	// println(colors)
	// 	mut cp := uic.colorpalette_component_from_id(app.window, 'palette')
	// 	cp.update_colors(colors)
	// }
}

// New
fn btn_new_click(a voidptr, b &ui.Button) {
	// println('new')
	htb_id := ui.component_id_from(b.id, 'htb')
	mut h := hideable_component_from_id(b.ui.window, htb_id)
	h.toggle()
}

fn btn_new_ok(a voidptr, b &ui.Button) {
	// // println('ok new')
	// tb := b.ui.window.textbox('tb')
	// mut h := hideable_component_from_id(b.ui.window, "htb")
	// mut dtv := treeview_by_id(b.ui.window, 'dtv')
	// if dtv.sel_id != '' {
	// 	sel_path := dtv.selected_full_title()
	// 	app.folder_to_open = if dtv.types[dtv.sel_id] == 'root' {
	// 		sel_path
	// 	} else {
	// 		os.dir(sel_path)
	// 	}
	// 	app.file = os.join_path(app.folder_to_open, *tb.text)
	// 	// println("open folder: ${app.folder_to_open}, new file: ${app.file}")
	// 	os.write_file(app.file, '') or {}
	// 	dtv.open(app.folder_to_open)
	// }
	// h.hide()
}

// Open folder
fn btn_open_click(a voidptr, b &ui.Button) {
	// // println('open')
	filebrowser_subwindow_visible(b.ui.window, ui.component_id_from(b.id, 'fb'))
}

fn btn_open_ok(a voidptr, b &ui.Button) {
	// println('ok')
	filebrowser_subwindow_close(b.ui.window, ui.component_id_from(b.id, 'fb'))
	fb := filebrowser_component(b)
	// app.folder_to_open = fb.selected_full_title()
	mut dtv := treeview_by_id(b.ui.window, ui.component_id_from(b.id, 'dtv'))
	// dtv.open(app.folder_to_open)
}

fn btn_open_cancel(a voidptr, b &ui.Button) {
	// println('cancel open')
	filebrowser_subwindow_close(b.ui.window, ui.component_id_from(b.id, 'fb'))
	// app.folder_to_open = ''
}

// Save file
fn btn_save_click(a voidptr, b &ui.Button) {
	// ui.component_parent_id(ui.menufile_component(b).id)
	// // // println("save")
	// mut rv := rasterview_component_from_id(b.ui.window, 'rv')
	// rv.save_to(app.file)
	// // tb := b.ui.window.textbox('edit')
	// // // println("text: <${*tb.text}>")
	// // mut app := &App(b.ui.window.state)
	// // // println(tb.text)
	// // os.write_file(app.file, tb.text) or {}
	// b.ui.window.root_layout.unfocus_all()
}
