module ui

import gx

//=== Tooltip ===//

// 1) From now, consider that widgets having tooltip are always on top and without intersecting other widgets.
// As a first try, this makes sense for visible widgets.
// Rmk: if we introduce hover event, this would be to consider.
// 2) It is assumed that there is only one tooltip drawn at the same time
// Rmk: popups are a bit different.
// 3) This is also devoted to simple widgets needing a quick system of help.

const (
	tooltip_margin = 5
)

struct TextLines {
mut:
	lines     []string
	x         int
	y         int
	width     int
	height    int
	text_cfg  gx.TextCfg
	text_size f64
}

struct Tooltip {
	TextLines
mut:
	id       string
	active   bool
	color    gx.Color = gx.black
	bg_color gx.Color = gx.Color{255, 220, 127, 220}
	side     Side     = .right
	ui       &UI      = 0
}

pub struct TooltipMessage {
	text string
	side Side = .right
}

[unsafe]
pub fn (t &Tooltip) free() {
	unsafe {
		for line in t.lines {
			line.free()
		}
		t.lines.free()
		// t.id.free()
	}
	$if free ? {
		println('\tTooltip -> freed')
	}
}

[unsafe]
pub fn (t &TooltipMessage) free() {
	unsafe {
		t.text.free()
		// t.id.free()
	}
	$if free ? {
		println('\tTooltipMessage -> freed')
	}
}

pub fn start_tooltip(mut w Widget, id string, msg TooltipMessage, wui &UI) {
	mut win := wui.window
	win.tooltip.id = id
	if !win.tooltip.active { // only once
		// println("start tooltip $win.tooltip.id: $msg")
		if win.tooltip.ui == 0 {
			unsafe {
				win.tooltip.ui = wui
			}
		}

		win.tooltip.lines = word_wrap_text_to_lines(msg.text, 70)
		win.tooltip.width, win.tooltip.height = text_lines_size(win.tooltip.lines, wui)

		win.tooltip.width += 2 * ui.tooltip_margin
		win.tooltip.height += 2 * ui.tooltip_margin

		set_text_cfg_color(mut win.tooltip, win.tooltip.color)
		set_text_cfg_style(mut win.tooltip, true, true, false)

		win.tooltip.active = true
		width, height := w.size()
		match msg.side {
			// TODO: the other sides
			.top {
				win.tooltip.x = w.x + w.offset_x + width / 2 - win.tooltip.width / 2
				win.tooltip.y = w.y + w.offset_y - win.tooltip.height - ui.tooltip_margin
			}
			.right {
				win.tooltip.x = w.x + w.offset_x + width + ui.tooltip_margin
				win.tooltip.y = w.y + w.offset_y + height / 2 - win.tooltip.height / 2
			}
			else {}
		}
	}
}

fn stop_tooltip(id string, wui &UI) {
	mut win := wui.window
	if win.tooltip.active && win.tooltip.id == id {
		// println("tooltip stop $win.tooltip.id")
		win.tooltip.active = false
	}
}

fn draw_tooltip(win Window) {
	if win.tooltip.active {
		// TODO:  add triangle to connect the rectangle
		// win.ui.gg.draw_rect(win.tooltip.x, win.tooltip.y, win.tooltip.width, win.tooltip.height,
		// gx.yellow)
		win.ui.gg.draw_rounded_rect_filled(win.tooltip.x, win.tooltip.y, win.tooltip.width,
			win.tooltip.height, .3, win.tooltip.bg_color)
		draw_text_lines(win.tooltip, win.tooltip.x + ui.tooltip_margin, win.tooltip.y,
			win.tooltip.lines)
	}
}

pub fn (mut w Window) append_tooltip(child Widget, tooltip TooltipMessage) {
	w.widgets_tooltip << child
	w.tooltips << tooltip
}

pub fn (mut w Window) update_tooltip(e &MouseMoveEvent) {
	for i, mut child in w.widgets_tooltip {
		id := child.id()
		if !child.hidden {
			if child.point_inside(e.x, e.y) && !w.dragger.activated {
				start_tooltip(mut child, id, w.tooltips[i], w.ui)
			} else {
				stop_tooltip(id, w.ui)
			}
		}
	}
}
