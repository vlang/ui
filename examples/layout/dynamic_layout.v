import ui

const win_width = 800
const win_height = 600

@[heap]
struct App {
mut:
	cpt int
}

fn main() {
	mut app := &App{}

	window := ui.window(
		width:  win_width
		height: win_height
		title:  'Dynamic layout'
		mode:   .resizable
		layout: ui.row(
			id:       'row'
			spacing:  10
			widths:   [.4, .6]
			heights:  ui.stretch
			children: [
				ui.column(
					id:       'col1'
					spacing:  10
					margin_:  10
					children: [
						ui.button(text: 'add last', on_click: app.btn_add_click),
						ui.button(text: 'add two', on_click: app.btn_add_two_click),
						ui.button(text: 'remove last', on_click: btn_remove_click),
						ui.button(text: 'remove second', on_click: btn_remove_second_click),
						ui.button(text: 'hide', on_click: btn_show_hide_click),
						ui.button(text: 'deactivate', on_click: btn_show_activate_click),
						ui.button(text: 'move', on_click: btn_move_click),
						ui.button(text: 'text last', on_click: btn_last_text_click),
						ui.button(text: 'text third', on_click: btn_third_text_click),
						ui.button(text: 'text below', on_click: btn_text_below_click),
						ui.button(text: 'switch', on_click: btn_switch_click),
						ui.button(text: 'migrate', on_click: btn_migrate_click),
					]
				),
				ui.column(
					id:       'col2'
					spacing:  10
					margin_:  10
					children: [
						ui.button(text: 'Button'),
					]
				),
			]
		)
	)
	ui.run(window)
}

fn btn_switch_click(btn &ui.Button) {
	window := btn.ui.window
	// Without id:
	// mut s := window.child() //root_layout
	// if mut s is ui.Stack {
	// 	s.move(from: 0, to: -1)
	// }
	mut s := window.get_or_panic[ui.Stack]('row')
	s.move(from: 0, to: -1)
}

fn btn_migrate_click(btn &ui.Button) {
	window := btn.ui.window
	mut s := window.child(0)
	mut t := window.child(1)
	if mut s is ui.Stack {
		if mut t is ui.Stack {
			s.move(
				from:   0
				target: t
				to:     -1
			)
		}
	}
}

fn (mut app App) btn_add_click(btn &ui.Button) {
	window := btn.ui.window
	mut s := window.get_or_panic[ui.Stack]('col2')
	app.cpt++
	s.add(
		child:   ui.button(text: 'Button ${app.cpt}')
		widths:  ui.stretch
		heights: ui.compact
		spacing: 10
	)
}

fn (mut app App) btn_add_two_click(btn &ui.Button) {
	window := btn.ui.window
	mut s := window.get_or_panic[ui.Stack]('col2')
	app.cpt++
	s.add(
		children: [ui.button(text: 'Button ${app.cpt++}'), ui.button(text: 'Button ${app.cpt}')]
		widths:   ui.stretch
		heights:  ui.compact
		spacing:  10
	)
}

fn btn_remove_click(btn &ui.Button) {
	window := btn.ui.window
	mut s := window.get_or_panic[ui.Stack]('col2')
	s.remove(at: -1)
}

fn btn_show_hide_click(btn &ui.Button) {
	window := btn.ui.window
	mut s := window.get_or_panic[ui.Stack]('col2')
	state := btn.text == 'show'
	s.set_children_visible(state, 0)
	mut b := unsafe { btn }
	b.text = if state { 'hide' } else { 'show' }
}

fn btn_show_activate_click(btn &ui.Button) {
	window := btn.ui.window
	mut s := window.get_or_panic[ui.Stack]('col2')
	state := btn.text == 'deactivate'
	if state {
		s.set_children_depth(ui.z_index_hidden, 0)
	} else {
		s.set_children_depth(0, 0)
	}
	mut b := unsafe { btn }
	b.text = if state { 'activate' } else { 'deactivate' }
	window.update_layout()
}

fn btn_remove_second_click(btn &ui.Button) {
	window := btn.ui.window
	mut s := window.get_or_panic[ui.Stack]('col2')
	if s.get_children().len > 1 {
		s.remove(at: 1)
	} else {
		ui.message_box('Second button not found')
	}
}

fn btn_move_click(btn &ui.Button) {
	window := btn.ui.window
	mut s := window.get_or_panic[ui.Stack]('col2')
	s.move(
		from: 0
		to:   -1
	)
}

fn btn_last_text_click(btn &ui.Button) {
	window := btn.ui.window
	mut w := window.child(1, -1)
	if mut w is ui.Button {
		ui.message_box('Last text button: ${w.text}')
	} else {
		ui.message_box('Third text button not found')
	}
}

fn btn_third_text_click(btn &ui.Button) {
	window := btn.ui.window
	mut w := window.child(1, 2)
	if mut w is ui.Button {
		ui.message_box('Third text button: ${w.text}')
	} else {
		ui.message_box('Third text button not found')
	}
}

fn btn_text_below_click(btn &ui.Button) {
	mut s := btn.parent
	if mut s is ui.Stack {
		// An example of extracting child from stack
		mut w := s.child(s.get_children().len - 2)
		if mut w is ui.Button {
			ui.message_box('Text below button: ${w.text}')
		}
	}
}
