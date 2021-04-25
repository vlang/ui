module ui

import gx

// 1) From now, consider that widgets having tooltip are always on top and without intersecting other widgets.
// As a first try, this makes sense for visible widgets.
// Rmk: if we introduce hover event, this would be to consider.
// 2) It is assumed that there is only one tooltip drawn at the same time
// Rmk: popups are a bit different.
// 3) This is also devoted to simple widgets needing a quick system of help.

const (
	tooltip_margin = 5
)

struct Tooltip {
pub mut:
	msg       string
	lines     []string
	active    bool
	x         int
	y         int
	width     int
	height    int
	side      Side = .top
	text_cfg  gx.TextCfg
	text_size f64
	ui        &UI = 0
}

pub fn start_tooltip(mut w Widget, msg string, wui &UI) {
	mut win := wui.window
	if !win.tooltip.active { // only once
		win.tooltip.msg = msg

		if win.tooltip.ui == 0 {
			win.tooltip.ui = wui
		}

		if win.tooltip.msg.contains('\n') {
			win.tooltip.lines = win.tooltip.msg.split('\n')
			mut tw, mut th := 0, 0
			win.tooltip.width, win.tooltip.height = 0, 0
			for line in win.tooltip.lines {
				tw, th = wui.gg.text_size(line)
				// println("tt line: $line -> ($tw, $th)")
				if tw > win.tooltip.width {
					win.tooltip.width = tw
				}
				win.tooltip.height += th
			}
		} else {
			win.tooltip.lines = []string{}
			win.tooltip.width, win.tooltip.height = wui.gg.text_size(msg)
			// println("tt msg: $msg -> ($win.tooltip.width, $win.tooltip.height)")
		}
		win.tooltip.width += 2 * ui.tooltip_margin
		win.tooltip.height += 2 * ui.tooltip_margin

		set_text_color(mut win.tooltip, gx.red)
		win.tooltip.active = true
		width, _ := w.size()
		win.tooltip.x = w.x + w.offset_x + width / 2 - win.tooltip.width / 2
		win.tooltip.y = w.y + w.offset_y - win.tooltip.height - ui.tooltip_margin
	}
}

fn stop_tooltip(w Widget, wui &UI) {
	mut win := wui.window
	win.tooltip.active = false
}

fn draw_tooltip(win Window) {
	if win.tooltip.active {
		match win.tooltip.side {
			.top {
				win.ui.gg.draw_rect(win.tooltip.x, win.tooltip.y, win.tooltip.width, win.tooltip.height,
					gx.yellow)
			}
			else {}
		}
		draw_text_lines(win.tooltip, win.tooltip.x + ui.tooltip_margin, win.tooltip.y,
			win.tooltip.lines)
	}
}
