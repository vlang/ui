module ui

import gx
import gg

interface DrawDevice {
	// related to text style
	has_text_style() bool
	set_text_style(font_name string, size int, color gx.Color, align int, vertical_align int)
	// drawing methods
	// draw_pixel(x f32, y f32, c gx.Color)
	// draw_pixels(points []f32, c gx.Color)
	draw_image(x f32, y f32, width f32, height f32, img &gg.Image)
	// draw_text_def(x int, y int, text string)
	draw_text_default(x int, y int, text string)
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
	draw_arc_empty(x f32, y f32, inner_radius f32, thickness f32, start_angle f32, end_angle f32, segments int, color gx.Color)
	draw_arc_filled(x f32, y f32, inner_radius f32, thickness f32, start_angle f32, end_angle f32, segments int, color gx.Color)
	draw_line(x f32, y f32, x2 f32, y2 f32, color gx.Color)
	draw_convex_poly(points []f32, color gx.Color)
	draw_poly_empty(points []f32, color gx.Color)
}
