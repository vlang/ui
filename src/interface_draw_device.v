module ui

import gx
import gg

pub interface DrawDevice {
	// text style
	has_text_style() bool
	set_text_style(font_name string, font_path string, size int, color gx.Color, align int, vertical_align int)
	draw_text_default(x int, y int, text string) // (ui) default ui TextStyle
	// text
	draw_text(x int, y int, text string, cfg gx.TextCfg)
	draw_text_def(x int, y int, text string) // (gg.Context) use set_text_cfg
	set_text_cfg(gx.TextCfg)
	text_size(string) (int, int)
	text_width(string) int
	text_height(string) int
	// drawing methods
	draw_pixel(x f32, y f32, c gx.Color, params gg.DrawPixelConfig)
	draw_pixels(points []f32, c gx.Color, params gg.DrawPixelConfig)
	draw_image(x f32, y f32, width f32, height f32, img &gg.Image)
	draw_triangle_empty(x f32, y f32, x2 f32, y2 f32, x3 f32, y3 f32, color gx.Color)
	draw_triangle_filled(x f32, y f32, x2 f32, y2 f32, x3 f32, y3 f32, color gx.Color)
	draw_rect_empty(x f32, y f32, w f32, h f32, color gx.Color)
	draw_rect_filled(x f32, y f32, w f32, h f32, color gx.Color)
	draw_rounded_rect_filled(x f32, y f32, w f32, h f32, radius f32, color gx.Color)
	draw_rounded_rect_empty(x f32, y f32, w f32, h f32, radius f32, border_color gx.Color)
	draw_circle_line(x f32, y f32, r int, segments int, color gx.Color)
	draw_circle_empty(x f32, y f32, r f32, color gx.Color)
	draw_circle_filled(x f32, y f32, r f32, color gx.Color)
	draw_slice_empty(x f32, y f32, r f32, start_angle f32, end_angle f32, segments int, color gx.Color)
	draw_slice_filled(x f32, y f32, r f32, start_angle f32, end_angle f32, segments int, color gx.Color)
	draw_arc_empty(x f32, y f32, radius f32, thickness f32, start_angle f32, end_angle f32, segments int, color gx.Color)
	draw_arc_filled(x f32, y f32, radius f32, thickness f32, start_angle f32, end_angle f32, segments int, color gx.Color)
	draw_arc_line(x f32, y f32, radius f32, start_angle f32, end_angle f32, segments int, color gx.Color)
	draw_line(x f32, y f32, x2 f32, y2 f32, color gx.Color)
	draw_convex_poly(points []f32, color gx.Color)
	draw_poly_empty(points []f32, color gx.Color)
	// clipping
	get_clipping() Rect
mut:
	reset_clipping()
	set_clipping(rect Rect)
	set_bg_color(color gx.Color)
}

fn (mut d DrawDevice) draw_window(mut w Window) {
	mut children := if unsafe { w.child_window == 0 } { w.children } else { w.child_window.children }

	for mut child in children {
		child.draw_device(mut d)
	}

	for mut sw in w.subwindows {
		sw.draw_device(mut d)
	}

	// draw dragger if active
	draw_dragger(mut w)
	// draw tooltip if active
	w.tooltip.draw_device(mut d)

	if w.on_draw != unsafe { nil } {
		w.on_draw(w)
	}

	w.mouse.draw_device(mut d)
}
