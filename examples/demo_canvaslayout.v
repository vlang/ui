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
			margin_: 10
			spacing: 10
			widths: [ui.compact, ui.compact] // 350.]
			heights: [ui.compact, ui.compact] // 300.]
			// scrollview: true
		}, [
			ui.picture(
			width: 100
			height: 100
			movable: true
			z_index: 20
			path: logo
		),
			ui.canvas_layout({
				on_draw: draw
				on_mouse_move: mouse_move
				scrollview: true
			}, [
				ui.at(10, 40, ui.row({ spacing: 10 }, [
					ui.button(z_index: 1, text: 'X'),
					ui.button(z_index: 1, text: 'Add'),
				])),
				ui.at(10, 10, ui.button(
					id: 'b_thm'
					text: 'Theme'
					width: 100
					theme: 'red'
					movable: true
					onclick: fn (a voidptr, b voidptr) {
						ui.message_box('Built with V UI')
					}
				)),
				ui.at(20, 280, ui.label(
					id: 'l_mm'
					text: '(0, 0)     '
				)),
				ui.at(120, 10, ui.dropdown({
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
				])),
				ui.at(10, 100, ui.listbox({
					width: 100
					height: 120
					on_change: lb_change
					// scrollview: false
					draw_lines: true
				}, map{
					'classic':  'Classic'
					'blue':     'Blue'
					'red':      'Red'
					'classic2': 'Classic'
					'blue2':    'Blue'
					'red2':     'Red'
					'classic3': 'Classic'
					'blue3':    'Blue'
					'red3':     'Red'
				})),
				ui.at(150, 100, ui.menu(
					id: 'menu'
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
				)),
				ui.at(150, 80, ui.button(
					text: 'hide/show menu'
					onclick: fn (a voidptr, b &ui.Button) {
						mut menu := b.ui.window.menu('menu')
						menu.hidden = !menu.hidden
					}
				)),
			]),
		]),
	])
	ui.run(window)
}

fn menu_click(m &ui.Menu, item &ui.MenuItem, app voidptr) {
	println('menu here $item.text')
}

fn dd_change(app voidptr, dd &ui.Dropdown) {
	println(dd.selected().text)
	win := dd.ui.window
	mut b := win.button('b_thm')
	b.set_theme(dd.selected().text)
	b.update_theme()
}

fn lb_change(app voidptr, lb &ui.ListBox) {
	id, _ := lb.selected() or { 'classic', '' }

	win := lb.ui.window
	mut b := win.button('b_thm')
	b.set_theme(id)
	b.update_theme()
}

fn draw(c &ui.CanvasLayout, app voidptr) {
	w, h := c.width, c.height
	c.draw_rect(0, 0, w, h, gx.white)
}

fn mouse_move(e ui.MouseMoveEvent, c &ui.CanvasLayout) {
	mut l := c.ui.window.label('l_mm')
	l.set_text('($e.x,$e.y)')
}
