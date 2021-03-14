module ui

import gx

pub struct Grid {
pub mut:
	header      []string
	body        [][]string
	x           int
	y           int
	height      int
	width       int
	z_index     int
	cell_height f32
	cell_width  f32 = 40
	parent      Layout
	is_focused  bool
	ui          &UI
	hidden      bool
}

pub struct GridConfig {
	header      []string
	body        [][]string
	height      int = 200
	width       int = 400
	z_index     int
	cell_height f32 = 25
}

fn (mut gv Grid) init(parent Layout) {
	gv.parent = parent
	ui := parent.get_ui()
	gv.ui = ui
}

pub fn grid(c GridConfig) &Grid {
	mut gv := &Grid{
		width: c.width
		height: c.height
		z_index: c.z_index
		cell_height: c.cell_height
		header: c.header
		body: c.body
		ui: 0
	}
	return gv
}

fn (mut gv Grid) draw() {
	cell_height := gv.cell_height
	cell_width := gv.cell_width
	body := gv.body
	header := gv.header
	check_cells(gv)
	x := gv.x
	mut y := gv.y
	mut text_width := 0
	mut text_height := 0
	// Outer border
	gv.ui.gg.draw_rect(x, y, gv.width, gv.height, gx.white)
	gv.ui.gg.draw_empty_rect(x, y, cell_width * header.len, cell_height, gx.gray)
	for i, c in header {
		// Vertical separators
		if i != 0 {
			gv.ui.gg.draw_line(x + cell_width * i, y, x + cell_width * i, y + cell_height,
				gx.gray)
		}
		// Text values
		text_width = gv.ui.gg.text_width(c)
		text_height = gv.ui.gg.text_height(c)
		gv.ui.gg.draw_text_def((int(cell_width) - text_width) / 2 + x + int(cell_width) * i,
			y + int(cell_height) / 2 - text_height / 2, c)
	}
	y += int(cell_height) * if gv.header.len == 0 { 0 } else { 1 }
	for ir, b_c in body {
		gv.ui.gg.draw_empty_rect(x, y + (cell_height * ir), cell_width * gv.body[0].len,
			cell_height, gx.gray)
		for i, c in b_c {
			// Vertical separators
			if i != 0 {
				gv.ui.gg.draw_line(x + cell_width * i, y, x + cell_width * i, y +
					cell_height * body.len, gx.gray)
			}
			// Text values
			text_width = gv.ui.gg.text_width(c)
			text_height = gv.ui.gg.text_height(c)
			gv.ui.gg.draw_text_def((int(cell_width) - text_width) / 2 + x + int(cell_width) * i,
				y + int(cell_height) * ir + int(cell_height) / 2 - text_height / 2, c)
		}
	}
}

fn min_text_width(gv Grid) int {
	mut min := 0
	for ch in gv.header {
		if gv.ui.gg.text_width(ch) > min {
			min = gv.ui.gg.text_width(ch)
		}
	}
	for ba in gv.body {
		for cb in ba {
			if gv.ui.gg.text_width(cb) > min {
				min = gv.ui.gg.text_width(cb)
			}
		}
	}
	return min
}

fn check_cells(gv Grid) int {
	mut len := 0
	for i, c in gv.body {
		if c.len > 0 {
			if i == 0 {
				len = c.len
				continue
			} else if len != c.len {
				panic('The number of rows cells must be equal')
			}
		}
	}
	if len != gv.header.len && gv.header.len != 0 {
		panic('The number of rows cells must be equal')
	}
	return len
}

fn (mut gv Grid) set_visible(state bool) {
	gv.hidden = state
}

fn (mut gv Grid) focus() {
	gv.is_focused = true
}

fn (mut gv Grid) unfocus() {
	gv.is_focused = false
}

fn (gv &Grid) is_focused() bool {
	return gv.is_focused
}

fn (mut gv Grid) set_pos(x int, y int) {
	gv.x = x
	gv.y = y
}

fn (mut gv Grid) size() (int, int) {
	return int(gv.width), int(gv.height)
}

fn (mut gv Grid) propose_size(w int, h int) (int, int) {
	gv.width = if gv.width == 0 || gv.width < gv.cell_width * check_cells(gv) { w } else { gv.width }
	gv.height = h
	gv.cell_width = f32(gv.width) / gv.body[0].len
	gv.cell_height = gv.cell_height
	return gv.width, gv.height
}

fn (gv &Grid) point_inside(x f64, y f64) bool {
	return x >= gv.x && x <= gv.x + gv.width && y >= gv.y && y <= gv.y + gv.height
}
