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
	adv := ctx.ft.fons.text_bounds(0, 0, text, &f32(unsafe { nil }))
	return adv / ctx.scale
}

pub fn (d DrawDeviceContext) text_bounds(x int, y int, text string) []f32 {
	ctx := d.Context
	mut buf := [4]f32{}
	ctx.ft.fons.text_bounds(x, y, text, &buf[0])
	asc, desc, lineh := f32(0), f32(0), f32(0)
	ctx.ft.fons.vert_metrics(&asc, &desc, &lineh)
	return [buf[0], buf[1], (buf[2] - buf[0]) / ctx.scale, (buf[3] - buf[1]) / ctx.scale,
		asc / ctx.scale, desc / ctx.scale, lineh / ctx.scale]
}

@[deprecated: 'use `widget.clipping` flag instead']
pub fn (d &DrawDeviceContext) scissor_rect(x int, y int, w int, h int) {
	d.Context.scissor_rect(x, y, w, h)
}
