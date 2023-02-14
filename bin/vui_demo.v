import ui
import ui.component as uic
import gx
import os
import time
import v.live

const (
	code_begin = '// ' + '<<BEGIN>>'
	code_end   = '// ' + '<<END>>'
	time_sleep = 500
	help_text  = $embed_file('help/vui_png.help').to_string()
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
	status_msg string
	code   string        = "app.btn_cb['btn_click'] = fn (_ &ui.Button) {
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
// vfmt on

fn (mut app App) set_status(txt string) {
	app.status_msg = txt
	println('status: ${txt}')
}

fn (mut app App) make_children() {
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
		text: &app.code
	)
	app.status = ui.textbox(mode: .read_only, text: &app.status_msg)
	app.layout = ui.box_layout(
		id: 'bl_root'
		children: {
			'run: (0,0) ++ (50,20)':     app.run_btn
			'status: (55,0) -> (1,20)':  app.status
			'edit: (0,20) ++ (1,.5)':    app.edit
			'active: (0, .5) ++ (1,.5)': app.active
		}
	)
}

// vfmt off
[live]
fn (mut app App) update_interactive() {
	mut layout := ui.box_layout()
// <<BEGIN>>
app.btn_cb['btn_click'] = fn (_ &ui.Button) {
	ui.message_box('coucou toto!')
}
layout = ui.box_layout(
  children: {
    'btn: (0.1, 0.4) -> (0.5,0.5)': ui.button(
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
	// <<END>>
	// To at least clean the event callers
	app.layout.children[app.layout.child_id.index("active")].cleanup()
	app.layout.update_child("active", mut layout)	
}
// vfmt on

fn (mut app App) run(_ &ui.Button) {
	app.set_status('recompiling...')
	println('heeeeeeee runnnnn')
	code := os.read_file(@FILE) or { panic(err) }
	pre_code := code.all_before(code_begin)
	post_code := code.all_after(code_end)
	reloads := live.info().reloads_ok
	last_ts := live.info().last_mod_ts
	reload_ms := live.info().reload_time_ms
	os.write_file(@FILE, pre_code + '${code_begin}\n' + app.code + '\n\t${code_end}' + post_code) or {
		panic(err)
	}
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
	app.edit.scrollview.set(0, .btn_y)
	ui.scrollview_reset(mut app.edit)
	app.edit.tv.sh.set_lang('.v')
	app.edit.is_line_number = true
}

fn main() {
	mut app := App{}
	app.make_children()
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
	sc.add_shortcut('ctrl + r', fn (mut app App) {
		app.run(app.run_btn)
	})
	sc.add_shortcut_context('ctrl + r', app)

	ui.run(app.window)
}
