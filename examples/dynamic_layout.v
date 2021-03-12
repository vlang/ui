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

	window := ui.window({
		width: win_width
		height: win_height
		state: app
		title: 'Dynamic layout'
		mode: .resizable
	}, [
		ui.row({
			spacing: 10
			widths: [.4, .6]
			heights: ui.stretch
		}, [ui.column({
			spacing: 10
			margin_: 10
		}, [
			ui.button(text: 'add last', onclick: btn_add_click),
			ui.button(text: 'add two', onclick: btn_add_two_click),
			ui.button(text: 'remove last', onclick: btn_remove_click),
			ui.button(text: 'remove second', onclick: btn_remove_second_click),
			ui.button(text: 'text last', onclick: btn_last_text_click),
			ui.button(text: 'text third', onclick: btn_third_text_click),
			ui.button(text: 'text above', onclick: btn_text_above_click),
		]), ui.column({
			spacing: 10
			margin_: 10
		}, [
			ui.button(text: 'Button'),
		])]),
	])
	ui.run(window)
}

fn btn_add_click(mut app State, btn &ui.Button) {
	window := btn.ui.window
	mut s := window.get_child(1) or { panic('bad index') }
	if s is ui.Stack {
		app.cpt++
		s.add(
			child: ui.button(text: 'Button $app.cpt')
			widths: ui.stretch
			heights: ui.compact
			spacing: 10
		)
	}
}

fn btn_add_two_click(mut app State, btn &ui.Button) {
	window := btn.ui.window
	mut s := window.get_child(1) or { panic('bad index') }
	if s is ui.Stack {
		app.cpt++
		s.add(
			children: [ui.button(text: 'Button ${app.cpt++}'),
				ui.button(text: 'Button $app.cpt'),
			]
			widths: ui.stretch
			heights: ui.compact
			spacing: 10
		)
	}
}

fn btn_remove_click(mut app State, btn &ui.Button) {
	window := btn.ui.window
	mut s := window.get_child(1) or { panic('bad index') }
	if s is ui.Stack {
		s.remove(
			widths: ui.stretch
			heights: ui.compact
			spacing: 10
		)
	}
}

fn btn_remove_second_click(mut app State, btn &ui.Button) {
	window := btn.ui.window
	mut s := window.get_child(1) or { panic('bad index') }
	if s is ui.Stack {
		if s.get_children().len > 1 {
			s.remove(
				at: 1
				widths: ui.stretch
				heights: ui.compact
				spacing: 10
			)
		} else {
			ui.message_box('Second button not found')
		}
	}
}

fn btn_last_text_click(mut app State, btn &ui.Button) {
	window := btn.ui.window
	mut w := window.get_child(1, -1) or { panic('bad index') }
	if w is ui.Button {
		ui.message_box('Last text button: $w.text')
	}
}

fn btn_third_text_click(mut app State, btn &ui.Button) {
	window := btn.ui.window
	mut w := window.get_child(1, 2) or {
		ui.message_box('Third text button not found')
		return
	}
	if w is ui.Button {
		ui.message_box('Third text button: $w.text')
	}
}

fn btn_text_above_click(mut app State, btn &ui.Button) {
	s := btn.parent
	if s is ui.Stack {
		mut w := s.get_child(s.get_children().len - 2) or { panic('bad index') }
		if w is ui.Button {
			ui.message_box('Text above button: $w.text')
		}
	}
}
