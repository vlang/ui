module editor

import ui
import ui.component as uic
import gx
import os

[heap]
pub struct AppEditor {
pub mut:
	id      string
	window  &ui.Window = unsafe { nil }
	layout  &ui.Layout = ui.empty_stack
	on_init ui.WindowFn
	// s
	line_numbers bool
}

[params]
pub struct AppEditorParams {
pub mut:
	id string
}

pub fn new(p AppEditorParams) &AppEditor {
	mut app := &AppEditor{
		id: p.id
	}
	app.make_layout()
	return app
}

pub fn (mut app AppEditor) run() {
	mut appl := ui.Application(app)
	appl.start()
}

pub fn (mut app AppEditor) make_layout() {
	mut dirs := ['.']
	dirs = dirs.map(os.real_path(it))
	app.line_numbers = true
	app.layout = ui.row(
		id: os.join_path(app.id, 'main')
		widths: [ui.stretch, ui.stretch * 2]
		children: [
			uic.hideable_stack(
				id: os.join_path(app.id, 'hmenu')
				layout: uic.menufile_stack(
					id: os.join_path(app.id, 'menu')
					dirs: dirs
					on_file_changed: fn [mut app] (mut mf uic.MenuFileComponent) {
						mf.layout.ui.window.set_title('V UI Edit: ${mf.file}')
						// reinit textbox scrollview
						// mut tb := mf.layout.ui.window.get_or_panic[ui.TextBox]('edit')
						mut tb := ui.Widget(mf.layout).get[ui.TextBox]('edit')
						tb.scrollview.set(0, .btn_y)
						ui.scrollview_reset(mut tb)
						tv := mf.treeview_component()
						tb.read_only = tv.types[mf.item_selected] == 'root'
						if app.line_numbers {
							tb.is_line_number = tv.types[mf.item_selected] != 'root'
						}
						unsafe {
							*(tb.text) = os.read_file(mf.file) or { '' }
						}
						tb.tv.sh.set_lang(os.file_ext(mf.file))
					}
					on_new: fn (mf &uic.MenuFileComponent) {
						// println("new $mf.file!!!")
						os.write_file(mf.file, '') or {}
					}
					on_save: fn (mf &uic.MenuFileComponent) {
						// println("save $mf.file")
						tb := mf.layout.ui.window.get_or_panic[ui.TextBox]('edit')
						// println("text: <${*tb.text}>")
						os.write_file(mf.file, tb.text) or {}
					}
				)
			),
			ui.textbox(
				mode: .multiline
				id: 'edit'
				z_index: 20
				height: 200
				line_height_factor: 1.0 // double the line_height
				text_size: 24
				text_font_name: 'fixed'
				bg_color: gx.hex(0xfcf4e4ff) // gx.rgb(252, 244, 228)
			),
		]
	)
	app.on_init = fn [mut app] (w &ui.Window) {
		// add shortcut for hmenu
		uic.hideable_add_shortcut(w, 'ctrl + o', fn [mut app] (w &ui.Window) {
			uic.hideable_toggle(w, os.join_path(app.id, 'hmenu'))
		})
		// At first hmenu open
		uic.hideable_show(w, os.join_path(app.id, 'hmenu'))
	}
}
