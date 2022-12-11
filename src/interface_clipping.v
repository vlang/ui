module ui

interface ClippingWidget {
mut:
	clipping bool
	width int
	height int
	x int
	y int
}

struct ClippingState {
	prev_x      int
	prev_y      int
	prev_width  int
	prev_height int
}

fn clipping_start(c ClippingWidget, mut d DrawDevice) ClippingState {
	if c.clipping {
		px, py, pw, ph := d.get_clipping()
		d.set_clipping(c.x, c.y, c.width, c.height)
		return ClippingState{
			prev_x: px
			prev_y: py
			prev_width: pw
			prev_height: ph
		}
	} else {
		return ClippingState{}
	}
}

fn clipping_end(c ClippingWidget, mut d DrawDevice, s ClippingState) {
	if c.clipping {
		d.set_clipping(s.prev_x, s.prev_y, s.prev_width, s.prev_height)
	}
}
