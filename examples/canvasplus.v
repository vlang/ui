import ui
import gx
import os

const (
	win_width   = 500
	win_height  = 385
	nr_cols     = 4
	cell_height = 25
	cell_width  = 100
	table_width = cell_width * nr_cols
)

struct User {
	first_name string
	last_name  string
	age        int
	country    string
}

// struct State {
// mut:
// 	window     &ui.Window = voidptr(0)
// 	label      &ui.Label
// 	country    &ui.Radio
// }

fn main() {
	mut logo := os.resource_abs_path(os.join_path('assets/img', 'logo.png'))
	$if android {
		logo = 'img/logo.png'
	}
	window := ui.window({
		width: win_width
		height: win_height
		title: 'V UI Demo'
		mode: .resizable
	}, [
		ui.row({
			margin_: .02
			spacing: .02
		}, [ui.canvas_plus(
			width: 400
			height: 275
			draw_fn: draw
			children: [
				ui.At{
					x: 10
					y: 2
					widget: ui.button(
						text: 'Theme'
						width: 100
						theme: 'red'
						onclick: fn (a voidptr, b voidptr) {
							ui.message_box('Built with V UI')
						}
					)
				},
				ui.At{
					x: 120
					y: 2
					widget: ui.dropdown({
						width: 140
						height: 20
						def_text: 'Select a theme'
						on_selection_changed: dd_change
					}, [
						{
							text: 'classic'
						},
						{
							text: 'blue'
						},
						ui.DropdownItem{
							text: 'red'
						},
					])
				},
				ui.At{
					x: 10
					y: 100
					widget: ui.listbox({
						width: 100
						height: 120
						draw_lines: true
					}, map{
						'res':  'Res'
						'toto': 'Toto'
						'titi': 'Titit'
					})
				},
				ui.At{
					x: 150
					y: 100
					widget: ui.menu(
						text: 'Menu'
						// width: 100
						// theme: 'red'
						items: [
							ui.MenuItem{
								text: 'Delete all users'
								action: menu_click
							},
							ui.MenuItem{
								text: 'Export users'
								action: menu_click
							},
							ui.MenuItem{
								text: 'Exit'
								action: menu_click
							},
						]
					)
				},
			]
		), ui.picture(
			width: 100
			height: 100
			path: logo
		)]),
	])
	ui.run(window)
}

fn menu_click(m &ui.Menu, item &ui.MenuItem, app voidptr) {
	println('menu here $item.text')
}

fn dd_change(app voidptr, dd &ui.Dropdown) {
	println(dd.selected().text)
	win := dd.ui.window
	mut b := win.child(0, 0)
	if mut b is ui.Button {
		b.set_theme(dd.selected().text)
		b.update_theme()
	} else {
		println('$b.type_name()')
	}
}

fn draw(c &ui.CanvasPlus, app voidptr) {
	w, h := c.width, c.height
	c.draw_rect(-20, 0, w + 120, h + 120, gx.white)
}
