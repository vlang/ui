import ui
import gx
import os

const (
	code_begin = '// ' + '<<BEGIN>>'
	code_end   = '// ' + '<<END>>'
)

[heap]
struct App {
mut:
	window &ui.Window    = unsafe { nil }
	layout &ui.BoxLayout = unsafe { nil }
	edit   &ui.TextBox   = unsafe { nil }
	code   string        = "layout = ui.box_layout(
		children: {
			'btn: (0.3, 0.3) -> (0.5,0.5)': ui.button(text: 'toto', width: 50, height: 20)
		}
	)"
	texts  map[string]string
	active ui.Widget = ui.empty_stack
}

fn (mut app App) make_interactive() {
	// complete the code and return
	app.active = ui.box_layout(
		children: {
			'btn: (0.3, 0.3) -> (0.5,0.5)': ui.button(text: 'toto', width: 50, height: 20)
		}
	)
}

[live]
fn (mut app App) update_interactive() {
	mut layout := ui.box_layout()
	// <<BEGIN>>
	layout = ui.box_layout(
		children: {
			'btn: (0.3, 0.3) -> (0.5,0.5)': ui.button(text: 'toto', width: 50, height: 20)
		}
	)
	// <<END>>
	app.layout.children[2] = layout
	layout.init(app.layout)
	app.window.update_layout()
}

fn (mut app App) run(_ &ui.Button) {
	code := os.read_file(@FILE) or { panic(err) }
	pre_code := code.all_before(code_begin)
	post_code := code.all_after(code_end)
	os.write_file(@FILE, pre_code + '${code_begin}\n' + app.code + '\n\t${code_end}' + post_code) or {
		panic(err)
	}
	app.update_interactive()
}

fn (mut app App) win_init(_ &ui.Window) {
	app.edit.scrollview.set(0, .btn_y)
	ui.scrollview_reset(mut app.edit)
	app.edit.tv.sh.set_lang('.v')
	app.edit.is_line_number = true
}

fn main() {
	mut app := App{}
	app.make_interactive()
	app.edit = ui.textbox(
		mode: .multiline
		scrollview: true
		z_index: 20
		height: 200
		line_height_factor: 1.0 // double the line_height
		text_size: 24
		text_font_name: 'fixed'
		bg_color: gx.hex(0xfcf4e4ff) // gx.rgb(252, 244, 228)
		text: &app.code
	)
	app.layout = ui.box_layout(
		id: 'bl_root'
		children: {
			'run: (0,0) ++ (50,20)':     ui.button(
				text: 'Run'
				bg_color: gx.light_blue
				on_click: app.run
			)
			'edit: (0,20) ++ (1,.5)':    app.edit
			'actice: (0, .5) ++ (1,.5)': app.active
		}
	)
	app.window = ui.window(
		width: 1000
		height: 800
		title: 'V UI: Demo'
		mode: .resizable
		on_init: app.win_init
		children: [app.layout]
	)
	ui.run(app.window)
}
