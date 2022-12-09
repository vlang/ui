module ui

import gg
import math

pub struct DrawDeviceContext {
	gg.Context
mut:
	clip_rect [4]int = [0, 0, math.max_i32, math.max_i32]!
}

pub fn (mut d DrawDeviceContext) reset_clipping() {
    // no need to actually set scissor_rect, it is reset each frame anyway, but
    // we do need to reset the clip_rect
	window_size := gg.window_size()
	d.clip_rect = [0, 0, window_size.width, window_size.height]!
}

pub fn (mut d DrawDeviceContext) set_clipping(x int, y int, w int, h int) {
	d.clip_rect = [x, y, w, h]!
	d.Context.scissor_rect(x, y, w, h)
}

pub fn (d DrawDeviceContext) get_clipping() (int, int, int, int) {
	return d.clip_rect[0], d.clip_rect[1], d.clip_rect[2], d.clip_rect[3]
}

[deprecated: 'use `widget.clipping` flag instead']
pub fn (d &DrawDeviceContext) scissor_rect(x int, y int, w int, h int) {
	d.Context.scissor_rect(x, y, w, h)
}
