import ui
import ui.component as uic
import gx
import os
import time
import v.live

const (
	begin_layout    = '// ' + '<<BEGIN_LAYOUT>>'
	end_layout      = '// ' + '<<END_LAYOUT>>'
	begin_main_pre  = '// ' + '<<BEGIN_MAIN_PRE>>'
	end_main_pre    = '// ' + '<<END_MAIN_PRE>>'
	begin_main_post = '// ' + '<<BEGIN_MAIN_POST>>'
	end_main_post   = '// ' + '<<END_MAIN_POST>>'
	begin_app       = '// ' + '<<BEGIN_APP>>'
	end_app         = '// ' + '<<END_APP>>'
	begin_import    = '// ' + '<<BEGIN_IMPORT>>'
	end_import      = '// ' + '<<END_IMPORT>>'
	begin_init      = '// ' + '<<BEGIN_INIT>>'
	end_init        = '// ' + '<<END_INIT>>'
	time_sleep      = 500
	help_text       = $embed_file('help/vui_demo.help').to_string()
	src_codes       = {
		'layout': "app.btn_cb['btn_click'] = fn (_ &ui.Button) { 
		ui.message_box('coucou toto!')
}
layout = ui.box_layout(
  children: {
    'btn: (0.2, 0.4) -> (0.5,0.5)': ui.button(
      text: 'show'
      on_click: fn (btn &ui.Button) {
        ui.message_box('Hi everybody !')
      }
    )
	'btn2: (0.7, 0.2) ++ (40,20)': ui.button(
      text: 'show2'
      on_click: app.btn_cb['btn_click']
	)
  }
)"
	}
)

// vfmt off
[heap]
struct App {
mut:
	window &ui.Window    = unsafe { nil }
	layout &ui.BoxLayout = unsafe { nil } 
	edit &ui.BoxLayout = unsafe{nil} // BoxLayout gathering all the textboxes
	edit_layout   &ui.TextBox   = unsafe { nil }
	edit_app   &ui.TextBox   = unsafe { nil }
	edit_extra   &ui.TextBox   = unsafe { nil }
	run_btn   &ui.Button 	 = unsafe { nil }
	status &ui.TextBox   	 = unsafe { nil }
	texts  map[string]string
	active ui.Widget = ui.empty_stack
	btn_cb map[string]fn(&ui.Button)
	boundings [][]string
	bounding_cur int
	boundings_edit [][]string
	bounding_edit_cur int
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
	app.boundings_edit = [
		['edit_layout: stretch', 'edit_app: hidden', 'edit_extra: hidden'],
		['edit_layout: hidden', 'edit_app: stretch', 'edit_extra: hidden'],
		['edit_layout: hidden', 'edit_app: hidden', 'edit_extra: stretch'],
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
	app.edit_layout = ui.textbox(
		mode: .multiline
		scrollview: true
		z_index: 20
		height: 200
		line_height_factor: 1.0 // double the line_height
		text_size: 24
		text_font_name: 'fixed'
		bg_color: gx.hex(0xfcf4e4ff) // gx.rgb(252, 244, 228)
		text_value: src_codes['layout']
	)
	app.edit_app = ui.textbox(
		mode: .multiline
		scrollview: true
		z_index: 20
		height: 200
		line_height_factor: 1.0 // double the line_height
		text_size: 24
		text_font_name: 'fixed'
		bg_color: gx.hex(0xfcf4e4ff) // gx.rgb(252, 244, 228)
	)
	app.edit_extra = ui.textbox(
		mode: .multiline
		scrollview: true
		z_index: 20
		height: 200
		line_height_factor: 1.0 // double the line_height
		text_size: 24
		text_font_name: 'fixed'
		bg_color: gx.hex(0xfcf4e4ff) // gx.rgb(252, 244, 228)
	)
	app.edit = ui.box_layout(
		children: {
			'edit_layout: stretch': app.edit_layout
			'edit_app: hidden':     app.edit_app
			'edit_extra: hidden':   app.edit_extra
		}
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

// vfmt off
[live]
fn (mut app App) update_interactive() {
	mut layout := ui.box_layout()
// <<BEGIN_LAYOUT>>
app.btn_cb['btn_click'] = fn (_ &ui.Button) { 
		ui.message_box('coucou toto!')
}
layout = ui.box_layout(
  children: {
    'btn: (0.2, 0.4) -> (0.5,0.5)': ui.button(
      text: 'show'
      on_click: fn (btn &ui.Button) {
        ui.message_box('Hi everybody !')
      }
    )
	'btn2: (0.7, 0.2) ++ (40,20)': ui.button(
      text: 'show2'
      on_click: app.btn_cb['btn_click']
	)
  }
)
	// <<END_LAYOUT>>
	// To at least clean the event callers
	app.layout.children[app.layout.child_id.index("active")].cleanup()
	app.layout.update_child("active", mut layout)	
}
// vfmt on

fn (mut app App) run(_ &ui.Button) {
	app.set_status('recompiling...')
	code := os.read_file(@FILE) or { panic(err) }
	pre_layout := code.all_before(begin_layout)
	post_layout := code.all_after(end_layout)
	reloads := live.info().reloads_ok
	last_ts := live.info().last_mod_ts
	reload_ms := live.info().reload_time_ms
	os.write_file(@FILE, pre_layout + '${begin_layout}\n' + app.edit_layout.get_text() +
		'\n\t${end_layout}' + post_layout) or { panic(err) }
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
	println('${reloads} ?= ${reloads2}  ${last_ts} ?= ${last_ts2} ${reload_ms} ?= ${reload_ms2}')
	time.sleep(time_sleep * time.millisecond)
	if reloads2 == reloads && reload_ms == reload_ms2 {
		ui.message_box('rerun since compilation failed: ${reloads} ?= ${reloads2}  ${last_ts} ?= ${last_ts2} ${reload_ms} ?= ${reload_ms2}')
	}
	app.update_interactive()
	app.set_status('reloaded....')
	spawn app.clear_status()
}

fn (mut app App) clear_status() {
	time.sleep(2000 * time.millisecond)
	app.set_status('')
}

fn (mut app App) win_init(_ &ui.Window) {
	app.edit_layout.scrollview.set(0, .btn_y)
	ui.scrollview_reset(mut app.edit_layout)
	app.edit_app.scrollview.set(0, .btn_y)
	ui.scrollview_reset(mut app.edit_app)
	app.edit_extra.scrollview.set(0, .btn_y)
	ui.scrollview_reset(mut app.edit_extra)
	app.edit_layout.tv.sh.set_lang('.v')
	app.edit_layout.is_line_number = true
	app.edit_app.tv.sh.set_lang('.v')
	app.edit_app.is_line_number = true
	app.edit_extra.tv.sh.set_lang('.v')
	app.edit_extra.is_line_number = true
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
		title: 'V UI: Demo'
		mode: .resizable
		on_init: app.win_init
		children: [app.layout]
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
	// POST CODE HERE
	app.make_postcode()
	ui.run(app.window)
}
