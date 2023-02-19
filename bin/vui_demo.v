import ui
import ui.component as uic
import ui.tools
import gx
import time
import v.live
import os

// vfmt off

const (
	time_sleep      = 500
	help_text       = $embed_file('help/vui_demo.help').to_string()
	src_codes       = {
		'demo/widgets/button': $embed_file('demo/widgets/button_ui.vv').to_string()
		'demo/widgets/label': $embed_file('demo/widgets/label_ui.vv').to_string()
		'demo/layouts/box_layout': $embed_file('demo/layouts/box_layout_ui.vv').to_string()
	}
)

[heap]
struct App {
mut:
	dt &tools.DemoTemplate = unsafe{nil}
	window &ui.Window    = unsafe { nil }
	layout &ui.BoxLayout = unsafe { nil } 
	edit &ui.TextBox = unsafe { nil }
	treedemo &ui.Stack = unsafe{ nil }
	treelayout &ui.Stack = unsafe{ nil }
	run_btn   &ui.Button 	 = unsafe { nil }
	status &ui.TextBox   	 = unsafe { nil }
	bounding_box  &ui.Rectangle = unsafe{ nil }
	texts  map[string]string
	active ui.Widget = ui.empty_stack
	boundings [][]string
	bounding_cur int
	bounding_box_cur string
	cache_code map[string]string
}

fn (mut app App) set_status(txt string) {
	app.status.set_text(txt)
	// println('status: ${txt}')
}

fn (mut app App) clear_status() {
	time.sleep(2000 * time.millisecond)
	app.set_status('')
}

fn (mut app App) make_children() {
	app.boundings = [
		['bb: hidden', 'treedemo: hidden', 'treelayout: hidden', 'run: (0,0) ++ (50,20)', 'status: (55,0) -> (1,20)', 'edit: (0,20) ++ (1,0.5)',
			'active: (0, 0.5) ++ (1,0.5)'],
		['bb: hidden','treedemo: hidden', 'treelayout: hidden','run: (0,0) ++ (50,20)', 'status: (55,0) -> (1,20)', 'edit: (0,20) -> (1,1)',
			'active: (0, 0) -> (0,0)'],
		['bb: hidden','treedemo: hidden', 'treelayout: hidden','run: hidden', 'status: hidden', 'edit: hidden  ', 'active: (0, 0) -> (1,1)'],
		['bb: hidden','treedemo: (0,20) ++ (0.3,1)', 'treelayout: hidden','run: (0,0) ++ (50,20)', 'status: (55,0) -> (1,20)', 'edit: (0.30,20) -> (1,0.5)  ', 'active: (0.3, 0.5) -> (1,1)'],
		['bb: hidden','treelayout: (0,20) ++ (0.3,1)', 'treedemo: hidden','run: (0,0) ++ (50,20)', 'status: (55,0) -> (1,20)', 'edit: (0.30,20) -> (1,0.5)  ', 'active: (0.3, 0.5) -> (1,1)'],
	]
	app.active = ui.box_layout(id: "active")
	app.run_btn = ui.button(
		text: 'Run'
		bg_color: gx.light_blue
		on_click: fn [mut app] (_ &ui.Button) {
			// println("btn run clicked")
			app.run()
		}
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
		text_value: src_codes[src_codes.keys()[0]]
	)
	app.treedemo = uic.treeview_stack(
		id: 'treedemo'
		trees: [
			tools.treedir("demo",os.join_path(os.dir(@FILE),'demo'))
		],
		on_click: fn [mut app](c &ui.CanvasLayout, mut tv uic.TreeViewComponent) {
			selected := tv.selected_full_title()
			if selected in src_codes {
				app.edit.set_text(src_codes[selected])
			}
		}
	)
	app.treelayout = tools.layouttree_stack(
		widget: app.active
		on_click: fn [mut app](c &ui.CanvasLayout, mut tv uic.TreeViewComponent) {
			app.bounding_box_cur = tv.titles[c.id]
			// println("selected $selected in widgets ${selected in app.window.widgets} ${app.window.widgets.keys()}")
			app.update_bounding_box()
		}
	)
	app.bounding_box = ui.rectangle(id: "bb", z_index: 10, color: gx.rgba(255,0, 0, 100))
	app.status = ui.textbox(mode: .read_only)
	app.layout = ui.box_layout(
		id: 'bl_root'
		children: {
			'run: (0,0) ++ (50,20)':       app.run_btn
			'treedemo: hidden':  ui.column(children: [app.treedemo])
			'treelayout: hidden': ui.column(children: [app.treelayout])
			'status: (55,0) -> (1,20)':    app.status
			'edit: (0,20) -> (1,0.5)':     app.edit
			'active: (0, 0.5) -> (1,1)': app.active
			'bb: hidden': app.bounding_box
		}
	)
	app.dt = tools.demo_template(@FILE, mut app.edit)
}

fn (mut app App) update_treelayout() {
	mut tvc := uic.treeview_component(app.treelayout)
	tools.layouttree_reopen(mut tvc, app.active)
}

fn (mut app App) update_bounding_box() {
	if app.bounding_box_cur in app.window.widgets {
		mut bb := app.window.widgets[app.bounding_box_cur]
		w, h := bb.size()
		// println("(${bb.x}, ${bb.y} ++ (${w}, ${h}))")
		app.layout.update_child_bounding("bb: (${bb.x}, ${bb.y} ++ (${w}, ${h}))") 
		// app.layout.update_layout()
	}
}

fn (mut app App) run() {
	// TODO: app.set_status below does not ork 
	app.set_status('recompiling...')
	reloads := live.info().reloads_ok
	last_ts := live.info().last_mod_ts
	reload_ms := live.info().reload_time_ms
	app.dt.write_file()
	mut reloads2 := live.info().reloads_ok
	mut last_ts2 := live.info().last_mod_ts
	mut reload_ms2 := live.info().reload_time_ms
	for _ in 0 .. 20 {
		if reloads2 != reloads || reload_ms != reload_ms2 {
			break
		}
		time.sleep(time_sleep * time.millisecond)
		reloads2 = live.info().reloads_ok
		last_ts2 = live.info().last_mod_ts
		reload_ms2 = live.info().reload_time_ms
	}
	// println('${reloads} ?= ${reloads2}  ${last_ts} ?= ${last_ts2} ${reload_ms} ?= ${reload_ms2}')
	time.sleep(time_sleep * time.millisecond)
	if reloads2 == reloads && reload_ms == reload_ms2 {
		ui.message_box('rerun since compilation failed: ${reloads} ?= ${reloads2}  ${last_ts} ?= ${last_ts2} ${reload_ms} ?= ${reload_ms2}')
	}
	app.update_interactive()
	app.set_status('reloaded....')
	spawn app.clear_status()
}

[live]
fn (mut app App) update_interactive() {
	mut layout := ui.box_layout()
// <<BEGIN_LAYOUT>>
// <<END_LAYOUT>>
	// To at least clean the event callers
	app.layout.children[app.layout.child_id.index("active")].cleanup()
	app.layout.update_child("active", mut layout)
	app.active = app.layout.children[app.layout.child_id.index("active")]
	app.update_treelayout()
}

[live]
fn (mut app App) make_precode() {
// <<BEGIN_MAIN_PRE>>
// <<END_MAIN_PRE>>
}

[live]
fn (mut app App) make_postcode() {
// <<BEGIN_MAIN_POST>>
// <<END_MAIN_POST>>
}

[live]
fn (mut app App) win_init(_ &ui.Window) {
	app.edit.scrollview.set(0, .btn_y)
	ui.scrollview_reset(mut app.edit)
	app.edit.tv.sh.set_lang('.v')
	app.edit.is_line_number = true
	
// <<BEGIN_WINDOW_INIT>>

// <<END_WINDOW_INIT>>
}

// vfmt on

fn (mut app App) resize(_ &ui.Window, _ int, _ int) {
	app.update_bounding_box()
}

fn main() {
	mut app := App{}
	app.make_children()
	// PRE CODE HERE
	app.make_precode()
	app.window = ui.window(
		width: 1000
		height: 800
		title: 'V UI: Demo'
		mode: .resizable
		on_init: app.win_init
		on_resize: app.resize
		children: [app.layout]
	)
	uic.messagebox_subwindow_add(mut app.window, id: 'help', text: help_text)
	mut sc := ui.Shortcutable(app.window)
	sc.add_shortcut_with_context('ctrl + r', fn (mut app App) {
		app.run()
	}, app)
	sc.add_shortcut_with_context('shift + right', fn (mut app App) {
		app.bounding_cur += 1
		if app.bounding_cur >= app.boundings.len {
			app.bounding_cur = 0
		}
		app.layout.update_child_bounding(...app.boundings[app.bounding_cur])
	}, app)
	sc.add_shortcut_with_context('shift + left', fn (mut app App) {
		app.bounding_cur -= 1
		if app.bounding_cur < 0 {
			app.bounding_cur = app.boundings.len - 1
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
	sc.add_shortcut_with_context('ctrl + n', fn (mut app App) {
		app.bounding_cur = 0
		app.layout.update_child_bounding(...app.boundings[app.bounding_cur])
	}, app)
	sc.add_shortcut_with_context('ctrl + o', fn (mut app App) {
		app.bounding_cur = 3
		app.layout.update_child_bounding(...app.boundings[app.bounding_cur])
	}, app)
	sc.add_shortcut_with_context('ctrl + b', fn (mut app App) {
		app.bounding_cur = 4
		app.layout.update_child_bounding(...app.boundings[app.bounding_cur])
	}, app)
	// POST CODE HERE
	app.make_postcode()
	ui.run(app.window)
}
