import ui
import ui.component as uic
import gx

const win_width = 800
const win_height = 600

@[heap]
struct App {
mut:
	window &ui.Window = unsafe { nil }
	// group
	first_ipsum  string
	second_ipsum string
	full_name    string
	// slider
	hor_slider  &ui.Slider = unsafe { nil }
	vert_slider &ui.Slider = unsafe { nil }
}

fn main() {
	mut app := &App{}
	app.hor_slider = ui.slider(
		width:            200
		height:           20
		orientation:      .horizontal
		max:              100
		val:              0
		on_value_changed: app.on_hor_value_changed
	)
	app.vert_slider = ui.slider(
		width:            20
		height:           200
		orientation:      .vertical
		max:              100
		val:              0
		on_value_changed: app.on_vert_value_changed
	)
	cr := ui.column(
		id:       'col_radio'
		widths:   ui.stretch
		margin_:  5
		spacing:  10
		children: [
			ui.row(
				spacing:  5
				children: [
					ui.label(text: 'Compact'),
					ui.switcher(open: true, on_click: on_switch_click),
				]
			),
			ui.radio(
				id:         'rh1'
				horizontal: true
				compact:    true
				values:     [
					'United States',
					'Canada',
					'United Kingdom',
					'Australia',
				]
				title:      'Country'
			),
			ui.radio(
				values: [
					'United States',
					'Canada',
					'United Kingdom',
					'Australia',
				]
				title:  'Country'
			),
			ui.row(
				widths:   [
					ui.compact,
					ui.stretch,
				]
				children: [
					ui.label(text: 'Country:'),
					ui.radio(
						id:         'rh2'
						horizontal: true
						compact:    true
						values:     ['United States', 'Canada', 'United Kingdom', 'Australia']
					),
				]
			),
		]
	)
	cdd := ui.column(
		id:       'col_dd'
		margin_:  5
		widths:   ui.compact
		children: [
			ui.dropdown(
				width:                140
				def_text:             'Select an option'
				on_selection_changed: dd_change
				items:                [
					ui.DropdownItem{
						text: 'Delete all users'
					},
					ui.DropdownItem{
						text: 'Export users'
					},
					ui.DropdownItem{
						text: 'Exit'
					},
				]
			),
			ui.rectangle(
				height: 100
				width:  250
				color:  gx.rgb(100, 255, 100)
			),
		]
	)
	rg := ui.row(
		id:       'row_group'
		margin_:  10
		height:   200
		spacing:  20
		children: [
			ui.group(
				title:    'First group'
				children: [
					ui.textbox(
						max_len:     20
						width:       200
						placeholder: 'Lorem ipsum'
						text:        &app.first_ipsum
					),
					ui.textbox(
						max_len:     20
						width:       200
						placeholder: 'dolor sit amet'
						text:        &app.second_ipsum
					),
					ui.button(
						text:     'More ipsum!'
						on_click: fn (b &ui.Button) {
							ui.open_url('https://lipsum.com/feed/html')
						}
					),
				]
			),
			ui.group(
				title:    'Second group'
				children: [
					ui.textbox(
						max_len:     20
						width:       200
						placeholder: 'Full name'
						text:        &app.full_name
					),
					ui.checkbox(checked: true, text: 'Do you like V?'),
					ui.button(text: 'Submit'),
				]
			),
		]
	)
	rs := ui.row(
		id:        'row_slider'
		height:    200
		alignment: .center
		widths:    [.1, .9]
		heights:   [.9, .1]
		margin:    ui.Margin{25, 25, 25, 25}
		spacing:   10
		children:  [app.vert_slider, app.hor_slider]
	)
	rect := ui.rectangle(
		text:   'Here a simple ui rectangle'
		color:  gx.red
		height: 100
		// text_color: gx.blue
		// text_align: gx.align_left
		// text_size: 30
	)
	window := ui.window(
		width:          win_width
		height:         win_height
		title:          'V UI: Accordion'
		native_message: false
		mode:           .resizable
		layout:         uic.accordion_stack(
			id:         'demo'
			text_color: gx.blue
			titles:     ['Rectangle', 'Radio', 'Slider', 'Group', 'Dropdown']
			children:   [rect, cr, rs, rg, cdd]
			heights:    [30.0, ui.compact]
			scrollview: true
		)
	)
	app.window = window
	ui.run(window)
}

fn on_switch_click(switcher &ui.Switch) {
	// switcher_state := if switcher.open { 'Enabled' } else { 'Disabled' }
	// app.label.set_text(switcher_state)
	mut rh1 := switcher.ui.window.get_or_panic[ui.Radio]('rh1')
	rh1.compact = !rh1.compact
	mut rh2 := switcher.ui.window.get_or_panic[ui.Radio]('rh2')
	rh2.compact = !rh2.compact
	switcher.ui.window.update_layout()
}

fn dd_change(dd &ui.Dropdown) {
	println(dd.selected().text)
}

fn (mut app App) on_hor_value_changed(slider &ui.Slider) {
	app.hor_slider.val = app.hor_slider.val
}

fn (mut app App) on_vert_value_changed(slider &ui.Slider) {
	app.vert_slider.val = app.vert_slider.val
}
