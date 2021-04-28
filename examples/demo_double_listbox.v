import ui

const (
	win_width  = 600
	win_height = 400
)

struct App {
mut:
	window &ui.Window
}

fn main() {
	mut app := &App{
		window: 0
	}
	window := ui.window({
		width: win_width
		height: win_height
		title: 'V UI: Composable Widget'
		state: app
		mode: .resizable
		native_message: false
	}, [
		ui.column({
			margin_: .05
			spacing: .05
			heights: [8 * ui.stretch, ui.stretch, ui.stretch]
		}, [
			ui.row({
			spacing: .1
			margin_: 5
			widths: ui.stretch
		}, [
			ui.doublelistbox(id: 'dlb1', title: 'dlb1', items: ['totto', 'titi']),
			ui.doublelistbox(id: 'dlb2', title: 'dlb2', items: ['tottoooo', 'titi', 'tototta']),
		]),
			ui.button(id: 'btn1', text: 'get values for dlb1', onclick: btn_click),
			ui.button(id: 'btn2', text: 'get values for dlb2', onclick: btn_click),
		]),
	])
	app.window = window
	ui.run(window)
}

fn btn_click(a voidptr, b &ui.Button) {
	dlbname := if b.id == 'btn1' { 'dlb1' } else { 'dlb2' }
	s := b.ui.window.stack(dlbname)
	println('$s.component_type()')
	dlb := ui.component_doublelistbox(s)
	res := 'result(s) of $dlbname : $dlb.values()'
	println(res)
	b.ui.window.message(res)
}
