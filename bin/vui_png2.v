import ui
import ui.component as uic
// import gx
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
					layout: uic.menufile_stack(
						id: 'menu'
						dirs: dirs
						on_file_changed: fn (mut mf uic.MenuFileComponent) {
							// println("hello $mf.file")
							if os.file_ext(mf.file) == '.png' {
								mf.layout.ui.window.set_title('V UI Png Edit: $mf.file')
								mut rv := uic.rasterview_component_from_id(mf.layout.ui.window,
									'rv')
								rv.load_image(mf.file)
								colors := rv.top_colors()
								mut cp := uic.colorpalette_component_from_id(mf.layout.ui.window,
									'palette')
								cp.update_colors(colors)
							}
						}
						on_new: fn (mf &uic.MenuFileComponent) {
							// println("new $mf.file!!!")
							if os.file_ext(mf.file) == '.png' {
								mut rv := uic.rasterview_component_from_id(mf.layout.ui.window,
									'rv')
								rv.new_image()
							}
						}
						on_save: fn (mf &uic.MenuFileComponent) {
							// println("save $mf.file")
							if os.file_ext(mf.file) == '.png' {
								mut rv := uic.rasterview_component_from_id(mf.layout.ui.window,
									'rv')
								rv.save_image_to(mf.file)
								mf.layout.ui.window.root_layout.unfocus_all()
							}
						}
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
	// uic.filebrowser_subwindow_add(mut window,
	// 	id: 'fb'
	// 	folder_only: true
	// 	width: 400
	// 	height: 300
	// 	x: 50
	// 	y: 50
	// 	bg_color: gx.white
	// 	on_click_ok: btn_open_ok
	// 	on_click_cancel: btn_open_cancel
	// )
	uic.colorbox_subwindow_add(mut window)
	ui.run(window)
}

fn init(w &ui.Window) {
	// add shortcut for hmenu
	uic.hideable_add_shortcut(w, 'ctrl + o', fn (w &ui.Window) {
		uic.hideable_toggle(w, 'hmenu')
	})
	// At first hmenu open
	uic.hideable_show(w, 'hmenu')

	// add shortcut for hpalette
	uic.hideable_add_shortcut(w, 'ctrl + p', fn (w &ui.Window) {
		uic.hideable_toggle(w, 'hpalette')
	})
	// At first hmenu open
	// uic.hideable_show(w, 'hpalette')
}
