import ui
import ui.component as uic
import gx
import os

const (
	win_width  = 800
	win_height = 600
)

struct App {
mut:
	window         &ui.Window
	text           string
	file           string
	folder_to_open string
	line_numbers   bool
}

fn main() {
	mut app := &App{
		window: 0
	}
	// TODO: use a proper parser loop, or even better - the `flag` module
	mut args := os.args#[1..]
	mut hidden_files := false
	if args.len > 0 {
		hidden_files = (args[0] in ['-H', '--hidden-files'])
	}
	if hidden_files {
		args = args#[1..]
	}
	app.line_numbers = true
	if args.len > 0 {
		if args[0] in ['-L', '--no-line-number'] {
			app.line_numbers = false
		}
	}
	if app.line_numbers {
		args = args#[1..]
	}
	mut dirs := args.clone()
	if dirs.len == 0 {
		dirs = ['.']
	}
	dirs = dirs.map(os.real_path(it))
	mut window := ui.window(
		width: win_width
		height: win_height
		title: 'V UI Png Edit: ${dirs[0]}'
		state: app
		native_message: false
		mode: .resizable
		on_init: init
		// on_char: on_char
		children: [
			ui.row(
				id: 'main'
				widths: [ui.stretch, ui.stretch * 2, 50]
				heights: ui.stretch
				children: [
					uic.hideable_stack(
					id: 'hmenu'
					layout: ui.column(
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
							children: [
								ui.button(
									tooltip: 'New File'
									tooltip_side: .right
									text: 'New'
									onclick: btn_new_click
									radius: .3
									z_index: 10
								),
								ui.button(
									tooltip: 'Open Folder'
									tooltip_side: .right
									text: 'Open'
									onclick: btn_open_click
									radius: .3
									z_index: 10
								),
								ui.button(
									tooltip: 'Save File'
									tooltip_side: .right
									text: 'Save'
									onclick: btn_save_click
									radius: .3
									z_index: 10
								),
							]
						),
							uic.hideable_stack(
								id: 'htb'
								layout: ui.row(
									id: 'htbl'
									margin_: 3
									heights: 24.0
									spacing: 3
									widths: [
										ui.stretch,
										24,
									]
									children: [
										ui.textbox(id: 'tb', z_index: 10),
										ui.button(
											id: 'tb_ok'
											text: 'Ok'
											z_index: 10
											radius: 5
											onclick: btn_new_ok
										),
									]
								)
							),
							ui.column(
								id: 'tvcol'
								scrollview: true
								heights: ui.compact
								bg_color: gx.hex(0xfcf4e4ff)
								children: [
									uic.dirtreeview_stack(
										id: 'dtv'
										trees: dirs
										hidden_files: hidden_files
										on_click: treeview_onclick
									),
								]
							)]
					)
				),
					uic.rasterview_canvaslayout(
						id: 'rv'
					),
					uic.hideable_stack(
						id: 'hpalette'
						layout: uic.colorpalette_stack(id: 'palette')
					)]
			),
		]
	)
	app.window = window
	uic.filebrowser_subwindow_add(mut window,
		id: 'fb'
		folder_only: true
		width: 400
		height: 300
		x: 50
		y: 50
		bg_color: gx.white
		on_click_ok: btn_open_ok
		on_click_cancel: btn_open_cancel
	)
	uic.colorbox_subwindow_add(mut window)
	ui.run(window)
}

fn treeview_onclick(c &ui.CanvasLayout, mut tv uic.TreeViewComponent) {
	selected := c.id
	mut app := &App(c.ui.window.state)
	app.file = tv.full_title(selected)
	// app.text = os.read_file(app.file) or { '' }
	if os.file_ext(app.file) == '.png' {
		app.window.set_title('V UI Png Edit: ${tv.titles[selected]}')
		mut rv := uic.rasterview_component_from_id(app.window, 'rv')
		rv.load(app.file)
		colors := rv.top_colors()
		// println("$app.file")
		// println(colors)
		mut cp := uic.colorpalette_component_from_id(app.window, 'palette')
		cp.update_colors(colors)
	}
}

fn btn_new_click(a voidptr, b &ui.Button) {
	// println('new')
	// uic.newfilebrowser_subwindow_visible(b.ui.window)
	// mut h := uic.hideable_component_from_id(b.ui.window, "htb")
	// h.toggle()
}

fn btn_open_click(a voidptr, b &ui.Button) {
	// // println('open')
	uic.filebrowser_subwindow_visible(b.ui.window)
}

fn btn_save_click(app &App, b &ui.Button) {
	// // println("save")
	mut rv := uic.rasterview_component_from_id(b.ui.window, 'rv')
	rv.save_to(app.file)
	// tb := b.ui.window.textbox('edit')
	// // println("text: <${*tb.text}>")
	// mut app := &App(b.ui.window.state)
	// // println(tb.text)
	// os.write_file(app.file, tb.text) or {}
	b.ui.window.root_layout.unfocus_all()
}

fn btn_open_ok(mut app App, b &ui.Button) {
	// println('ok')
	uic.filebrowser_subwindow_close(b.ui.window)
	fb := uic.filebrowser_component(b)
	app.folder_to_open = fb.selected_full_title()
	mut dtv := uic.treeview_by_id(b.ui.window, 'dtv')
	dtv.open(app.folder_to_open)
}

fn btn_open_cancel(mut app App, b &ui.Button) {
	// // println('cancel open')
	// uic.filebrowser_subwindow_close(b.ui.window)
	// app.folder_to_open = ''
}

fn btn_new_ok(mut app App, b &ui.Button) {
	// // println('ok new')
	// tb := b.ui.window.textbox('tb')
	// mut h := uic.hideable_component_from_id(b.ui.window, "htb")
	// mut dtv := uic.treeview_by_id(b.ui.window, 'dtv')
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

fn init(w &ui.Window) {
	// add shortcut for hmenu
	uic.hideable_add_char_shortcut(w, 'ctrl + o', fn (w &ui.Window) {
		uic.hideable_toggle(w, 'hmenu')
	})
	// At first hmenu open
	uic.hideable_show(w, 'hmenu')

	// add shortcut for hpalette
	uic.hideable_add_char_shortcut(w, 'ctrl + p', fn (w &ui.Window) {
		uic.hideable_toggle(w, 'hpalette')
	})
	// At first hmenu open
	// uic.hideable_show(w, 'hpalette')
}
