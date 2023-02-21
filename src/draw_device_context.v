module ui

import gg

pub struct DrawDeviceContext {
	gg.Context
mut:
	clip_rect Rect
}

// TODO: documentation
pub fn (mut d DrawDeviceContext) reset_clipping() {
	// no need to actually set scissor_rect, it is reset each frame anyway, but
	// we do need to reset the clip_rect
	size := gg.window_size()
	d.clip_rect = Rect{
		x: 0
		y: 0
		w: size.width
		h: size.height
	}
	$if ui_clipping ? {
		println('clip: reset')
	}
}

// TODO: documentation
pub fn (mut d DrawDeviceContext) set_clipping(rect Rect) {
	d.clip_rect = rect
	d.Context.scissor_rect(rect.x, rect.y, rect.w, rect.h)
	$if ui_clipping ? {
		println('clip: set ${rect.x} ${rect.y} ${rect.w} ${rect.h}')
	}
}

// TODO: documentation
pub fn (d DrawDeviceContext) get_clipping() Rect {
	return d.clip_rect
}

// TODO: documentation
pub fn (d DrawDeviceContext) text_width_additive(text string) f64 {
	ctx := d.Context
	adv := ctx.ft.fons.text_bounds(0, 0, text, &f32(0))
	return adv / ctx.scale
}

[deprecated: 'use `widget.clipping` flag instead']
pub fn (d &DrawDeviceContext) scissor_rect(x int, y int, w int, h int) {
	d.Context.scissor_rect(x, y, w, h)
}
