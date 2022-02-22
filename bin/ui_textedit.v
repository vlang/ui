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
}

fn main() {
	mut app := &App{
		window: 0
	}
	dir := os.args[1] or { os.real_path('.') }
	mut window := ui.window(
		width: win_width
		height: win_height
		title: 'V UI TextEdit: $dir'
		state: app
		native_message: false
		mode: .resizable
		// on_init: init
		// on_char: on_char
		children: [
			ui.row(
				widths: [ui.stretch, ui.stretch * 2]
				children: [
					ui.column(
					heights: [40.0, ui.stretch]
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
						ui.column(
							id: 'tvcol'
							scrollview: true
							heights: ui.compact
							bg_color: gx.hex(0xfcf4e4ff)
							children: [
								uic.dirtreeview(
									id: 'dtv'
									trees: [dir]
									on_click: treeview_onclick
								),
							]
						)]
				),
					ui.textbox(
						mode: .multiline
						id: 'edit'
						z_index: 20
						height: 200
						text: &app.text
						text_size: 24
						bg_color: gx.hex(0xfcf4e4ff) // gx.rgb(252, 244, 228)
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
	uic.newfilebrowser_subwindow_add(mut window,
		id: 'nfb'
		folder_only: true
		width: 400
		height: 300
		x: 50
		y: 50
		bg_color: gx.white
		on_click_ok: btn_new_ok
		on_click_cancel: btn_new_cancel
	)
	ui.run(window)
}

fn treeview_onclick(c &ui.CanvasLayout, mut tv uic.TreeView) {
	selected := c.id
	mut app := &App(c.ui.window.state)
	app.file = tv.full_title(selected)
	app.text = os.read_file(app.file) or { '' }
	app.window.set_title('V UI TextEdit: ${tv.titles[selected]}')
}

fn btn_new_click(a voidptr, b &ui.Button) {
	println('new')
	uic.newfilebrowser_subwindow_visible(b.ui.window)
	// mut l := b.ui.window.stack('tvcol')
	// // mut tv := uic.component_treeview(b.ui.window.stack('tv'))
	// // tv.cleanup_layout()
	// l.remove(at: 0)
	// dir := '/Users/rcqls/vlang'
	// l.add(
	// 	at: 0
	// 	child: treeview_dir(dir)
	// )
}

fn btn_open_click(a voidptr, b &ui.Button) {
	// println('open')
	uic.filebrowser_subwindow_visible(b.ui.window)
}

fn btn_save_click(a voidptr, b &ui.Button) {
	// println("saveeee")
	tb := b.ui.window.textbox('edit')
	// println("text: <${*tb.text}>")
	mut app := &App(b.ui.window.state)
	// println(tb.text)
	os.write_file(app.file, tb.text) or {}
	b.ui.window.root_layout.unfocus_all()
}

fn btn_open_ok(mut app App, b &ui.Button) {
	// println('ok')
	uic.filebrowser_subwindow_close(b.ui.window)
	fb := uic.component_filebrowser(b)
	app.folder_to_open = fb.selected_full_title()
	mut dtv := uic.treeview_by_id(b.ui.window, 'dtv')
	dtv.open(app.folder_to_open)
}

fn btn_open_cancel(mut app App, b &ui.Button) {
	// println('cancel')
	uic.filebrowser_subwindow_close(b.ui.window)
	app.folder_to_open = ''
}

fn btn_new_ok(mut app App, b &ui.Button) {
	println('ok')
	uic.newfilebrowser_subwindow_close(b.ui.window)
	fb := uic.component_filebrowser(b)
	app.folder_to_open = fb.selected_full_title()
	// mut l := b.ui.window.stack('tvcol')
	// l.remove(at: 0)
	// l.add(
	// 	at: 0
	// 	child: uic.treeview_dir(
	// 		id: 'tv'
	// 		trees: [app.folder_to_open]
	// 		on_click: treeview_onclick
	// 	)
	// )
}

fn btn_new_cancel(mut app App, b &ui.Button) {
	println('cancel')
	uic.newfilebrowser_subwindow_close(b.ui.window)
	app.folder_to_open = ''
}

// fn on_char(e ui.KeyEvent, w &ui.Window) {
// 	if ui.super_alt_key(e.mods) && e.codepoint == 210 {
// 		println("save")
// 	} else {
// 		println(e)
// 	}

// }

// fn init(win &ui.Window) {
// }
