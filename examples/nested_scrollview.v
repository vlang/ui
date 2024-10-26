import ui

const win_width = 550
const win_height = 300

const box_width = 110
const box_height = 90

const area_width = 600
const area_height = 400
const area_spacing = 10

const instructions = 'Run v -d ui_scroll_nest and scroll inside/outside scrollviews'

const single_column_of_boxes = false

struct App {
mut:
	box_text []string
}

fn make_scroll_area_box(mut app App, r string, c string) ui.Widget {
	app.box_text << 'box${r}${c}\n...\n...\n...\n...\n...\n...\n...\n...\n...'
	return ui.textbox(
		id:           'box${r}${c}'
		width:        box_width
		height:       box_height
		is_multiline: true
		text:         &app.box_text[app.box_text.len - 1]
	)
}

fn make_scroll_area_row(mut app App, r string) ui.Widget {
	return ui.row(
		spacing:  area_spacing
		children: [
			make_scroll_area_box(mut app, r, '-1'),
			make_scroll_area_box(mut app, r, '-2'),
			make_scroll_area_box(mut app, r, '-3'),
			make_scroll_area_box(mut app, r, '-4'),
			make_scroll_area_box(mut app, r, '-5'),
		]
	)
}

fn make_scroll_area(mut app App) ui.Widget {
	mut kids := []ui.Widget{}

	if single_column_of_boxes {
		kids << make_scroll_area_box(mut app, '', '-1')
		kids << make_scroll_area_box(mut app, '', '-2')
		kids << make_scroll_area_box(mut app, '', '-3')
		kids << make_scroll_area_box(mut app, '', '-4')
		kids << make_scroll_area_box(mut app, '', '-5')
	} else {
		kids << make_scroll_area_row(mut app, '-0')
		kids << make_scroll_area_row(mut app, '-1')
		kids << make_scroll_area_row(mut app, '-2')
		kids << make_scroll_area_row(mut app, '-3')
		kids << make_scroll_area_row(mut app, '-4')
		kids << make_scroll_area_row(mut app, '-5')
	}

	return ui.column(
		id:         'scroll-column'
		margin_:    area_spacing
		spacing:    area_spacing
		scrollview: true
		children:   kids
	)
}

fn win_key_down(w &ui.Window, e ui.KeyEvent) {
	if e.key == .escape {
		// TODO: w.close() not implemented (no multi-window support yet!)
		if w.ui.dd is ui.DrawDeviceContext {
			w.ui.dd.quit()
		}
	}
}

fn main() {
	mut app := App{}
	mut win := ui.window(
		width:       win_width
		height:      win_height
		title:       'V nested scrollviews'
		on_key_down: win_key_down
		mode:        .resizable
		layout:      ui.column(
			heights:  [ui.stretch, 20.0]
			widths:   ui.stretch
			children: [make_scroll_area(mut app), ui.label(
				text: &instructions
			)]
		)
	)
	ui.run(win)
}
