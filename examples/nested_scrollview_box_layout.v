import ui
import gx

const win_width = 550
const win_height = 300

const box_width = 110
const box_height = 90

struct App {
mut:
	box_text []string
}

fn make_scroll_area(mut app App) ui.Widget {
	mut kids, mut decl := map[string]ui.Widget{}, ''
	for r in 0 .. 5 {
		for c in 0 .. 5 {
			id := 'box${r}_${c}'
			app.box_text << 'box${r}${c}\n...\n...\n...\n...\n...\n...\n...\n...\n...'
			$if fixed ? {
				decl = '${id}: (${r * 110},${c * 90}) ++ (100,80)'
			} $else $if fixed_spacing ? {
				decl = '${id}: (${r * 1.0 / 5},${c * 1.0 / 5}) ++ (${1.0 / 5 - 0.01},${1.0 / 5 - .01})'
			} $else {
				decl = '${id}: (${r * 1.0 / 5},${c * 1.0 / 5}) ++ (${1.0 / 5 - 0.01},${1.0 / 5 - .01})'
			}
			kids[decl] = ui.textbox(
				width:        box_width
				height:       box_height
				bg_color:     gx.white
				is_multiline: true
				text:         &app.box_text[app.box_text.len - 1]
			)
		}
	}

	return ui.box_layout(
		id:       'bl'
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
	mut win := ui.window(
		width:       win_width
		height:      win_height
		title:       'V nested scrollviews inside boxlayout '
		on_key_down: win_key_down
		mode:        .resizable
		layout:      ui.column(
			scrollview: true
			widths:     ui.stretch
			heights:    ui.stretch
			bg_color:   gx.yellow
			children:   [
				make_scroll_area(mut app),
			]
		)
	)
	ui.run(win)
}
