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
	ui       &UI      = unsafe { nil }
	widgets  []Widget
	tooltips []TooltipMessage
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

fn (mut t Tooltip) init(wui &UI) {
	unsafe {
		t.ui = wui
	}
}

pub fn (mut t Tooltip) start(mut w Widget, id string, msg TooltipMessage) {
	t.id = id
	if !t.active {
		t.lines = word_wrap_text_to_lines(msg.text, 70)
		t.width, t.height = text_lines_size(t.lines, t.ui)

		t.width += 2 * ui.tooltip_margin
		t.height += 2 * ui.tooltip_margin

		set_text_cfg_color(mut t, t.color)
		set_text_cfg_style(mut t, true, true, false)

		t.active = true
		width, height := w.size()
		match msg.side {
			// TODO: the other sides
			.top {
				t.x = w.x + w.offset_x + width / 2 - t.width / 2
				t.y = w.y + w.offset_y - t.height - ui.tooltip_margin
			}
			.right {
				t.x = w.x + w.offset_x + width + ui.tooltip_margin
				t.y = w.y + w.offset_y + height / 2 - t.height / 2
			}
			else {}
		}
	}
}

fn (mut t Tooltip) stop(id string) {
	if t.active && t.id == id {
		// println("tooltip stop $t.id")
		t.active = false
	}
}

fn (mut t Tooltip) draw() {
	t.draw_device(mut t.ui.dd)
}

fn (t &Tooltip) draw_device(mut d DrawDevice) {
	if t.active {
		// TODO:  add triangle to connect the rectangle
		// win.ui.dd.draw_rect(win.tooltip.x, win.tooltip.y, win.tooltip.width, win.tooltip.height,
		// gx.yellow)
		d.draw_rounded_rect_filled(t.x, t.y, t.width, t.height, .3, t.bg_color)
		draw_text_lines(t, t.x + ui.tooltip_margin, t.y, t.lines)
	}
}

pub fn (mut t Tooltip) append(child Widget, tooltip TooltipMessage) {
	t.widgets << child
	t.tooltips << tooltip
}

pub fn (mut t Tooltip) update(e &MouseMoveEvent) {
	dragger := t.ui.window.dragger
	for i, mut child in t.widgets {
		id := child.id()
		if !child.hidden {
			if child.point_inside(e.x, e.y) && !dragger.activated {
				t.start(mut child, id, t.tooltips[i])
			} else {
				t.stop(id)
			}
		}
	}
}

// pub fn (mut w Window) append_tooltip(child Widget, tooltip TooltipMessage) {
// 	w.widgets_tooltip << child
// 	w.tooltips << tooltip
// }

// pub fn (mut w Window) update_tooltip(e &MouseMoveEvent) {
// 	for i, mut child in w.widgets_tooltip {
// 		id := child.id()
// 		if !child.hidden {
// 			if child.point_inside(e.x, e.y) && !w.dragger.activated {
// 				start_tooltip(mut child, id, w.tooltips[i], w.ui)
// 			} else {
// 				stop_tooltip(id, w.ui)
// 			}
// 		}
// 	}
// }
