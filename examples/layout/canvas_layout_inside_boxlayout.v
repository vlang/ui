import ui
import gx
import os

const win_width = 550
const win_height = 385

fn main() {
	mut logo := os.resource_abs_path(os.join_path('../assets/img', 'logo.png'))
	$if android {
		logo = 'img/logo.png'
	}
	mut text := 'gcghchc\n fvfyfy' + 'titi\n'.repeat(10)
	mut window := ui.window(
		width:   win_width
		height:  win_height
		title:   'V UI Demo'
		mode:    .resizable
		on_init: win_init
		layout:  ui.box_layout(
			children: {
				'demo_cl: (40,0) -> (1,1)': ui.canvas_layout(
					on_draw:         draw
					active_evt_mngr: false
					on_mouse_move:   mouse_move
					full_width:      win_width - 20
					full_height:     win_height
					scrollview:      true
					children:        [
						ui.at(10, 40, ui.row(
							spacing:  10
							heights:  ui.compact
							children: [
								ui.button(z_index: 10, text: 'X'),
								ui.button(z_index: 10, text: 'Add'),
							]
						)),
						ui.at(10, 10, ui.button(
							id:        'b_thm'
							text:      'Theme'
							width:     100
							theme:     'red'
							z_index:   10
							movable:   true
							hoverable: true
							on_click:  fn (b &ui.Button) {
								ui.message_box('Built with V UI')
							}
						)),
						ui.at(20, 340, ui.label(
							id:   'l_mm'
							text: '(0, 0)     '
						)),
						ui.at(120, 10, ui.dropdown(
							width:                140
							height:               20
							def_text:             'Select a theme'
							on_selection_changed: dd_change
							items:                [
								ui.DropdownItem{
									text: 'default'
								},
								ui.DropdownItem{
									text: 'blue'
								},
								ui.DropdownItem{
									text: 'red'
								},
							]
						)),
						ui.at(10, 70, ui.listbox(
							width:     100
							height:    140
							z_index:   10
							on_change: lb_change
							ordered:   true
							// scrollview: false
							draw_lines: true
							items:      {
								'default':  'Classic'
								'blue':     'Blue'
								'red':      'Red'
								'classic2': 'Classic2'
								'blue2':    'Blue2'
								'red2':     'Red2'
								'classic3': 'Classic3'
								'blue3':    'Blue3'
								'red3':     'Red3'
							}
						)),
						ui.at(50, 220, ui.listbox(
							width:      100
							height:     100
							z_index:    10
							on_change:  lb_change_multi
							scrollview: false
							// selectable: false
							ordered:    true
							multi:      true
							draw_lines: true
							items:      {
								'classic': 'Classic'
								'blue':    'Blue'
								'red':     'Red'
							}
						)),
						ui.at(200, 220, ui.listbox(
							width:      100
							height:     100
							z_index:    10
							on_change:  lb_change_multi
							scrollview: false
							// selectable: false
							ordered:    true
							multi:      true
							draw_lines: true
							bg_color:   gx.red
							items:      {
								'classic': 'Classic'
							}
						)),
						ui.at(150, 100, ui.menu(
							id:    'menu'
							text:  'Menu'
							width: 200
							items: [
								ui.menuitem(
									text:   'Delete all users'
									action: menu_click
								),
								ui.menuitem(
									text:   'Export users'
									action: menu_click
								),
								ui.menuitem(
									text:   'Exit'
									action: menu_click
								),
							]
						)),
						ui.at(150, 80, ui.button(
							text:     'hide/show menu'
							z_index:  10
							on_click: fn (b &ui.Button) {
								mut menu := b.ui.window.get_or_panic[ui.Menu]('menu')
								menu.hidden = !menu.hidden
							}
						)),
						ui.at(300, 30, ui.textbox(
							id:       'tb'
							width:    150
							height:   100
							mode:     .multiline
							bg_color: gx.yellow
							text:     &text
						)),
					]
				)
				'pic: (10,10) ++ (20,20)':  ui.picture(
					width:        20
					height:       20
					movable:      true
					z_index:      20
					path:         logo
					tooltip:      'press Shift to drag'
					tooltip_side: .right
				)
			}
		)
	)
	ui.run(window)
}

fn menu_click(item &ui.MenuItem) {
	println('menu here ${item.text}')
}

fn dd_change(dd &ui.Dropdown) {
	println(dd.selected().text)
	win := dd.ui.window
	mut b := win.get_or_panic[ui.Button]('b_thm')
	b.update_theme_style(dd.selected().text)
}

fn lb_change(lb &ui.ListBox) {
	id, _ := lb.selected() or { 'classic', '' }

	win := lb.ui.window
	mut b := win.get_or_panic[ui.Button]('b_thm')
	b.update_theme_style(id)
}

fn lb_change_multi(lb &ui.ListBox) {
	println(lb.items.map('${it.text}: ${it.selected} ${it.disabled}'))
}

fn draw(mut d ui.DrawDevice, c &ui.CanvasLayout) {
	w, h := c.full_width, c.full_height
	c.draw_device_rect_filled(d, 0, 0, w, h, gx.white)
}

fn mouse_move(c &ui.CanvasLayout, e ui.MouseMoveEvent) {
	mut l := c.ui.window.get_or_panic[ui.Label]('l_mm')
	l.set_text('(${e.x},${e.y})')
}

fn win_init(mut w ui.Window) {
	// w.mouse.start(ui.mouse_hidden)
}
