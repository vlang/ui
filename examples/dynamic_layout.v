import ui

const (
	win_width  = 800
	win_height = 600
)

struct State {
mut:
	cpt int
}

fn main() {
	mut app := &State{}

	window := ui.window(
		width: win_width
		height: win_height
		state: app
		title: 'Dynamic layout'
		mode: .resizable
		children: [
			ui.row(
				id: 'row'
				spacing: 10
				widths: [.4, .6]
				heights: ui.stretch
				children: [
					ui.column(
					id: 'col1'
					spacing: 10
					margin_: 10
					children: [
						ui.button(text: 'add last', onclick: btn_add_click),
						ui.button(text: 'add two', onclick: btn_add_two_click),
						ui.button(text: 'remove last', onclick: btn_remove_click),
						ui.button(text: 'remove second', onclick: btn_remove_second_click),
						ui.button(text: 'hide', onclick: btn_show_hide_click),
						ui.button(text: 'deactivate', onclick: btn_show_activate_click),
						ui.button(text: 'move', onclick: btn_move_click),
						ui.button(text: 'text last', onclick: btn_last_text_click),
						ui.button(text: 'text third', onclick: btn_third_text_click),
						ui.button(text: 'text below', onclick: btn_text_below_click),
						ui.button(text: 'switch', onclick: btn_switch_click),
						ui.button(text: 'migrate', onclick: btn_migrate_click),
					]
				),
					ui.column(
						id: 'col2'
						spacing: 10
						margin_: 10
						children: [
							ui.button(text: 'Button'),
						]
					),
				]
			),
		]
	)
	ui.run(window)
}

fn btn_switch_click(mut app State, btn &ui.Button) {
	window := btn.ui.window
	// Without id:
	// mut s := window.child() //root_layout
	// if mut s is ui.Stack {
	// 	s.move(from: 0, to: -1)
	// }
	mut s := window.stack('row')
	s.move(from: 0, to: -1)
}

fn btn_migrate_click(mut app State, btn &ui.Button) {
	window := btn.ui.window
	mut s := window.child(0)
	mut t := window.child(1)
	if mut s is ui.Stack {
		if mut t is ui.Stack {
			s.move(
				from: 0
				target: t
				to: -1
			)
		}
	}
}

fn btn_add_click(mut app State, btn &ui.Button) {
	window := btn.ui.window
	mut s := window.stack('col2')
	app.cpt++
	s.add(
		child: ui.button(text: 'Button $app.cpt')
		widths: ui.stretch
		heights: ui.compact
		spacing: 10
	)
}

fn btn_add_two_click(mut app State, btn &ui.Button) {
	window := btn.ui.window
	mut s := window.stack('col2')
	app.cpt++
	s.add(
		children: [ui.button(text: 'Button ${app.cpt++}'), ui.button(text: 'Button $app.cpt')]
		widths: ui.stretch
		heights: ui.compact
		spacing: 10
	)
}

fn btn_remove_click(mut app State, btn &ui.Button) {
	window := btn.ui.window
	mut s := window.stack('col2')
	s.remove(at: -1)
}

fn btn_show_hide_click(mut app State, btn &ui.Button) {
	window := btn.ui.window
	mut s := window.stack('col2')
	state := btn.text == 'show'
	s.set_children_visible(state, 0)
	mut b := btn
	b.text = if state { 'hide' } else { 'show' }
}

fn btn_show_activate_click(mut app State, btn &ui.Button) {
	window := btn.ui.window
	mut s := window.stack('col2')
	state := btn.text == 'deactivate'
	if state {
		s.set_children_depth(ui.z_index_hidden, 0)
	} else {
		s.set_children_depth(0, 0)
	}
	mut b := btn
	b.text = if state { 'activate' } else { 'deactivate' }
	window.update_layout()
}

fn btn_remove_second_click(mut app State, btn &ui.Button) {
	window := btn.ui.window
	mut s := window.stack('col2')
	if s.get_children().len > 1 {
		s.remove(at: 1)
	} else {
		ui.message_box('Second button not found')
	}
}

fn btn_move_click(mut app State, btn &ui.Button) {
	window := btn.ui.window
	mut s := window.stack('col2')
	s.move(
		from: 0
		to: -1
	)
}

fn btn_last_text_click(mut app State, btn &ui.Button) {
	window := btn.ui.window
	mut w := window.child(1, -1)
	if mut w is ui.Button {
		ui.message_box('Last text button: $w.text')
	} else {
		ui.message_box('Third text button not found')
	}
}

fn btn_third_text_click(mut app State, btn &ui.Button) {
	window := btn.ui.window
	mut w := window.child(1, 2)
	if mut w is ui.Button {
		ui.message_box('Third text button: $w.text')
	} else {
		ui.message_box('Third text button not found')
	}
}

fn btn_text_below_click(mut app State, btn &ui.Button) {
	s := btn.parent
	if mut s is ui.Stack {
		// An example of extracting child from stack
		mut w := s.child(s.get_children().len - 2)
		if mut w is ui.Button {
			ui.message_box('Text below button: $w.text')
		}
	}
}
