module ui

import math

pub interface AdjustableWidget {
	size() (int, int)
mut:
	id string
	justify []f64 // 0.0 means left, 0.5 center and 1.0 right (0.25 means 1/4 of the free space between size and adjusted size)
	x int
	y int
	set_pos(int, int)
	adj_size() (int, int)
}

fn (mut w AdjustableWidget) set_adjusted_pos(x int, y int) {
	width, height := w.size()
	adj_width, adj_height := w.adj_size()
	dw := math.max(width - adj_width, 0.0)
	dh := math.max(height - adj_height, 0.0)
	aw, ah := w.justify[0], w.justify[1]
	w.set_pos(int(x + aw * dw), int(y + ah * dh))
}

pub const (
	top_left      = [0.0, 0.0]
	top_center    = [0.5, 0.0]
	top_right     = [1.0, 0.0]
	center_left   = [0.0, 0.5]
	center        = [0.5, 0.5]
	center_center = [0.5, 0.5]
	center_right  = [1.0, 0.5]
	bottom_left   = [0.0, 1.0]
	bottom_center = [0.5, 1.0]
	bottom_right  = [1.0, 1.0]
)
