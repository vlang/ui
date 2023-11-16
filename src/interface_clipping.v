module ui

pub interface ClippingWidget {
mut:
	clipping bool
	width    int
	height   int
	x        int
	y        int
}

type ClippingState = Rect

fn clipping_start(c ClippingWidget, mut d DrawDevice) !ClippingState {
	if c.clipping {
		mut x, mut y := c.x, c.y
		if c is ScrollableWidget {
			if has_scrollview(c) {
				x, y = c.scrollview.orig_xy()
			}
		}
		existing := d.get_clipping()
		impose := Rect{
			x: x
			y: y
			w: c.width
			h: c.height
		}
		intersection := existing.intersection(impose)
		if intersection.is_empty() {
			return error('widget is occluded and can not be drawn')
		}
		$if clipping_start ? {
			if c is ScrollableWidget {
				println('clipping start ${c.id} ${intersection} ${existing} ${impose}')
			}
		}
		d.set_clipping(intersection)
		return existing
	} else {
		return ClippingState{}
	}
}

fn clipping_end(c ClippingWidget, mut d DrawDevice, s ClippingState) {
	if c.clipping {
		$if clipping_end ? {
			if c is ScrollableWidget {
				println('clipping end ${c.id} ${s}')
			}
		}
		d.set_clipping(s)
	}
}
