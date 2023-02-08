import ui
import gx

const (
	win_width  = 550
	win_height = 300

	box_width  = 110
	box_height = 90
)

struct App {
mut:
	box_text []string
}

fn make_scroll_area(mut app App) ui.Widget {
	mut kids := map[string]ui.Widget{}
	for r in 0 .. 5 {
		for c in 0 .. 5 {
			id := 'box${r}_${c}'
			app.box_text << 'box${r}${c}\n...\n...\n...\n...\n...\n...\n...\n...\n...'
			kids['${id}: (${r * 110},${c * 90}) ++ (100,80)'] = ui.row(
				children: [
					ui.textbox(
						width: box_width
						height: box_height
						bg_color: gx.white
						is_multiline: true
						text: &app.box_text[app.box_text.len - 1]
					),
				]
			)
		}
	}

	return ui.box_layout(
		id: 'bl'
		children: kids
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
	kids := make_scroll_area(mut app)
	mut win := ui.window(
		width: win_width
		height: win_height
		title: 'V nested scrollviewsboxlayout inside '
		on_key_down: win_key_down
		mode: .resizable
		children: [
			// ui.column(
			// 	heights: ui.stretch
			// 	widths: ui.stretch
			// 	children: [
			kids,
			// 	]
			// ),
		]
	)
	ui.run(win)
}
