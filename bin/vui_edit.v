import ui
import ui.component as uic
import gx
import os

const win_width = 800
const win_height = 600

struct App {
mut:
	window       &ui.Window = unsafe { nil }
	line_numbers bool
}

fn main() {
	mut app := &App{
		window: unsafe { nil }
	}
	// TODO: use a proper parser loop, or even better - the `flag` module
	mut args := os.args#[1..].clone()
	mut hidden_files := false
	if args.len > 0 {
		hidden_files = (args[0] in ['-H', '--hidden-files'])
	}
	if hidden_files {
		args = args#[1..].clone()
	}
	app.line_numbers = true
	if args.len > 0 {
		if args[0] in ['-L', '--no-line-number'] {
			app.line_numbers = false
		}
	}
	if app.line_numbers {
		args = args#[1..].clone()
	}
	mut dirs := args.clone()
	if dirs.len == 0 {
		dirs = ['.']
	}
	dirs = dirs.map(os.real_path(it))
	mut window := ui.window(
		width:          win_width
		height:         win_height
		title:          'V UI Edit: ${dirs[0]}'
		native_message: false
		mode:           .resizable
		on_init:        init
		// on_char: on_char
		layout: ui.row(
			id:       'main'
			widths:   [ui.stretch, ui.stretch * 2]
			children: [
				uic.hideable_stack(
					id:     'hmenu'
					layout: uic.menufile_stack(
						id:              'menu'
						dirs:            dirs
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
						on_new:          fn (mf &uic.MenuFileComponent) {
							// println("new $mf.file!!!")
							os.write_file(mf.file, '') or {}
						}
						on_save:         fn (mf &uic.MenuFileComponent) {
							// println("save $mf.file")
							tb := mf.layout.ui.window.get_or_panic[ui.TextBox]('edit')
							// println("text: <${*tb.text}>")
							os.write_file(mf.file, tb.text) or {}
						}
					)
				),
				ui.textbox(
					mode:               .multiline
					id:                 'edit'
					z_index:            20
					height:             200
					line_height_factor: 1.0 // double the line_height
					text_size:          24
					text_font_name:     'fixed'
					bg_color:           gx.hex(0xfcf4e4ff) // gx.rgb(252, 244, 228)
				),
			]
		)
	)
	app.window = window
	ui.run(window)
}

fn init(w &ui.Window) {
	// add shortcut for hmenu
	uic.hideable_add_shortcut(w, 'ctrl + o', fn (w &ui.Window) {
		uic.hideable_toggle(w, 'hmenu')
	})
	// At first hmenu open
	uic.hideable_show(w, 'hmenu')
}
