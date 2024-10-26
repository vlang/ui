import ui
import ui.component as uic
import ui.tools
import gx
import time
import os
import x.json2

const time_sleep = 500
const help_text = $embed_file('help/vui_demo.help').to_string()
const demos_json = $embed_file('assets/demos.json').to_string()

// vfmt off
@[heap]
struct App {
mut:
	window &ui.Window    = unsafe { nil }
	layout &ui.BoxLayout = unsafe { nil } 
	edit   &ui.TextBox   = unsafe { nil }
	active   &ui.TextBox   = unsafe { nil }
	treedemo &ui.Stack = unsafe{ nil }
 	toolbar &ui.Stack = unsafe{ nil }
	run_btn   &ui.Button 	 = unsafe { nil }
	help_btn   &ui.Button 	 = unsafe { nil }
	reset_btn   &ui.Button 	 = unsafe { nil }
	status &ui.TextBox   	 = unsafe { nil }
	texts  map[string]string
	btn_cb map[string]fn(&ui.Button)
	boundings [][]string
	bounding_cur int
	cache_code map[string]string
}
// vfmt on

fn (mut app App) set_status(txt string) {
	app.status.set_text(txt)
	println('status: ${txt}')
}

fn (mut app App) make_cache_code() {
	src_codes := (json2.raw_decode(demos_json) or { panic(err) }).as_map()
	for key, val in src_codes {
		app.cache_code[key] = val.str()
	}
}

fn (mut app App) make_children() {
	app.boundings = [
		['toolbar: (0,0) -> (1,20)', 'bb: hidden', 'treedemo: hidden', 'edit: (0,20) -> (1,0.5)',
			'active: (0, 0.5) -> (1,0.5)'],
		['toolbar: (0,0) -> (1,20)', 'bb: hidden', 'treedemo: hidden', 'treelayout: hidden',
			'edit: (0,20) -> (1,1)', 'active: (0, 0) -> (0,0)'],
		['toolbar: hidden', 'bb: hidden', 'treedemo: hidden', 'edit: hidden  ',
			'active: (0, 0) -> (1,1)'],
		['toolbar: (0,0) -> (1,20)', 'bb: hidden', 'treedemo: (0,20) -> (0.3,1)',
			'edit: (0.3,20) -> (1,0.5)', 'active: (0.3, 0.5) -> (1,1)'],
	]
	app.run_btn = ui.button(
		text:     'Run'
		bg_color: gx.light_blue
		// on_click: app.run
	)
	app.help_btn = ui.button(
		text:     ' ? '
		bg_color: gx.light_green
		on_click: fn [mut app] (_ &ui.Button) {
			mut sw := app.window.get_or_panic[ui.SubWindow]('help')
			sw.set_visible(sw.hidden)
		}
	)
	app.reset_btn = ui.button(
		text:     ' Reset '
		bg_color: gx.orange
		on_click: fn [mut app] (_ &ui.Button) {
			app.reset()
		}
	)
	app.status = ui.textbox(mode: .read_only)
	app.toolbar = ui.row(
		id:       'toolbar'
		margin_:  2
		spacing:  2
		bg_color: gx.black
		widths:   [ui.compact, ui.compact, ui.compact, ui.stretch]
		children: [app.run_btn, app.help_btn, app.reset_btn, app.status]
	)
	app.edit = ui.textbox(
		mode:               .multiline
		scrollview:         true
		z_index:            20
		height:             200
		line_height_factor: 1.0 // double the line_height
		text_size:          24
		text_font_name:     'fixed'
		bg_color:           gx.hex(0xfcf4e4ff) // gx.rgb(252, 244, 228)
		text_value:         app.cache_code[app.cache_code.keys()[0]]
	)
	app.active = ui.textbox(
		mode:               .read_only | .multiline
		scrollview:         true
		z_index:            20
		height:             200
		line_height_factor: 1.0 // double the line_height
		text_size:          24
		text_font_name:     'fixed'
		bg_color:           gx.white
	)
	app.treedemo = uic.treeview_stack(
		id:       'treedemo'
		trees:    [
			tools.treedir('widgets', os.join_path(os.dir(@FILE), 'demo', 'widgets')),
			tools.treedir('layouts', os.join_path(os.dir(@FILE), 'demo', 'layouts')),
			tools.treedir('components', os.join_path(os.dir(@FILE), 'demo', 'components')),
		]
		on_click: fn [mut app] (c &ui.CanvasLayout, mut tv uic.TreeViewComponent) {
			selected := tv.selected_full_title()
			if selected in app.cache_code {
				app.edit.set_text(app.cache_code[selected])
			}
		}
	)
	app.layout = ui.box_layout(
		id:       'bl_root'
		children: {
			'toolbar: (0,0) ++ (1,20)':  app.toolbar
			'treedemo: hidden':          ui.column(children: [app.treedemo])
			'edit: (0,20) -> (1,0.5)':   app.edit
			'active: (0, 0.5) -> (1,1)': app.active
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

fn (mut app App) reset() {
	app.edit.set_text('')
}

fn main() {
	mut app := App{}
	app.make_cache_code()
	app.make_children()
	app.window = ui.window(
		width:   1000
		height:  800
		title:   'V UI: Build App'
		mode:    .resizable
		on_init: app.win_init
		layout:  app.layout
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
		app.layout.update_boundings(...app.boundings[app.bounding_cur])
	}, app)
	sc.add_shortcut_with_context('ctrl + e', fn (mut app App) {
		app.bounding_cur = 1
		app.layout.update_boundings(...app.boundings[app.bounding_cur])
	}, app)
	sc.add_shortcut_with_context('ctrl + v', fn (mut app App) {
		app.bounding_cur = 2
		app.layout.update_boundings(...app.boundings[app.bounding_cur])
	}, app)
	sc.add_shortcut_with_context('ctrl + e', fn (mut app App) {
		app.bounding_cur = 1
		app.layout.update_boundings(...app.boundings[app.bounding_cur])
	}, app)
	sc.add_shortcut_with_context('ctrl + 2', fn (mut app App) {
		app.bounding_cur = 0
		app.layout.update_boundings(...app.boundings[app.bounding_cur])
	}, app)
	ui.run(app.window)
}
