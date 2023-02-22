import ui
import ui.component as uic
import gx
import time

const (
	time_sleep = 500
	help_text  = $embed_file('help/vui_build.help').to_string()
	src_codes  = {
		'button': $embed_file('demo/button_ui.vv').to_string()
	}
)

// vfmt off
[heap]
struct App {
mut:
	window &ui.Window    = unsafe { nil }
	layout &ui.BoxLayout = unsafe { nil } 
	edit   &ui.TextBox   = unsafe { nil }
	run_btn   &ui.Button 	 = unsafe { nil }
	status &ui.TextBox   	 = unsafe { nil }
	texts  map[string]string
	active ui.Widget = ui.empty_stack
	btn_cb map[string]fn(&ui.Button)
	boundings [][]string
	bounding_cur int
}
// vfmt on

fn (mut app App) set_status(txt string) {
	app.status.set_text(txt)
	println('status: ${txt}')
}

fn (mut app App) make_children() {
	app.boundings = [
		['run: (0,0) ++ (50,20)', 'status: (55,0) -> (1,20)', 'edit: (0,20) ++ (1,0.5)',
			'active: (0, 0.5) ++ (1,0.5)'],
		['run: (0,0) ++ (50,20)', 'status: (55,0) -> (1,20)', 'edit: (0,20) -> (1,1)',
			'active: (0, 0) -> (0,0)'],
		['run: hidden', 'status: hidden', 'edit: hidden  ', 'active: (0, 0) -> (1,1)'],
	]
	app.active = ui.box_layout(
		children: {
			'btn: (0.2, 0.4) -> (0.5,0.5)': ui.button(
				text: 'show'
				on_click: fn (btn &ui.Button) {
					ui.message_box('Hi everybody !')
				}
			)
			'btn2: (0.7, 0.2) ++ (40,20)':  ui.button(
				text: 'show2'
				on_click: app.btn_cb['btn_click']
			)
		}
	)
	app.run_btn = ui.button(
		text: 'Run'
		bg_color: gx.light_blue
		on_click: app.run
	)
	app.edit = ui.textbox(
		mode: .multiline
		scrollview: true
		z_index: 20
		height: 200
		line_height_factor: 1.0 // double the line_height
		text_size: 24
		text_font_name: 'fixed'
		bg_color: gx.hex(0xfcf4e4ff) // gx.rgb(252, 244, 228)
		text_value: src_codes['button']
	)
	app.status = ui.textbox(mode: .read_only)
	app.layout = ui.box_layout(
		id: 'bl_root'
		children: {
			'run: (0,0) ++ (50,20)':       app.run_btn
			'status: (55,0) -> (1,20)':    app.status
			'edit: (0,20) ++ (1,0.5)':     app.edit
			'active: (0, 0.5) ++ (1,0.5)': app.active
		}
	)
}

fn (mut app App) run(_ &ui.Button) {
	app.set_status('recompiling...')
	// TODO
	app.set_status('reloaded....')
	spawn app.clear_status()
}

fn (mut app App) clear_status() {
	time.sleep(2000 * time.millisecond)
	app.set_status('')
}

fn (mut app App) win_init(_ &ui.Window) {
	app.edit.scrollview.set(0, .btn_y)
	ui.scrollview_reset(mut app.edit)
	app.edit.tv.sh.set_lang('.v')
	app.edit.is_line_number = true
}

// vfmt off
// <BEGIN_CALLBACK>
// <END_CALLBACK>

fn (mut app App) make_precode() {
// <BEGIN_MAIN_PRE>
// <END_MAIN_PRE>
}

fn (mut app App) make_postcode() {
// <BEGIN_MAIN_POST>
// <END_MAIN_POST>
}

// vfmt on

fn main() {
	mut app := App{}
	app.make_children()
	// PRE CODE HERE
	app.make_precode()
	app.window = ui.window(
		width: 1000
		height: 800
		title: 'V UI: Build App'
		mode: .resizable
		on_init: app.win_init
		layout: app.layout
	)
	uic.messagebox_subwindow_add(mut app.window, id: 'help', text: help_text)
	mut sc := ui.Shortcutable(app.window)
	sc.add_shortcut_with_context('ctrl + r', fn (mut app App) {
		app.run(app.run_btn)
	}, app)
	sc.add_shortcut_with_context('ctrl + l', fn (mut app App) {
		app.bounding_cur += 1
		if app.bounding_cur >= app.boundings.len {
			app.bounding_cur = 0
		}
		app.layout.update_child_bounding(...app.boundings[app.bounding_cur])
	}, app)
	sc.add_shortcut_with_context('ctrl + e', fn (mut app App) {
		app.bounding_cur = 1
		app.layout.update_child_bounding(...app.boundings[app.bounding_cur])
	}, app)
	sc.add_shortcut_with_context('ctrl + v', fn (mut app App) {
		app.bounding_cur = 2
		app.layout.update_child_bounding(...app.boundings[app.bounding_cur])
	}, app)
	sc.add_shortcut_with_context('ctrl + e', fn (mut app App) {
		app.bounding_cur = 1
		app.layout.update_child_bounding(...app.boundings[app.bounding_cur])
	}, app)
	sc.add_shortcut_with_context('ctrl + 2', fn (mut app App) {
		app.bounding_cur = 0
		app.layout.update_child_bounding(...app.boundings[app.bounding_cur])
	}, app)
	ui.run(app.window)
}
