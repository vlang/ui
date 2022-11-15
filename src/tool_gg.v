module ui

import gg
import gx
import math

pub fn intersection_rect(r1 gg.Rect, r2 gg.Rect) gg.Rect {
	// top left and bottom right points
	tl_x, tl_y := math.max(r1.x, r2.x), math.max(r1.y, r2.y)
	br_x, br_y := math.min(r1.x + r1.width, r2.x + r2.width), math.min(r1.y + r1.height,
		r2.y + r2.height)
	// intersection
	r := gg.Rect{f32(tl_x), f32(tl_y), f32(br_x - tl_x), f32(br_y - tl_y)}
	return r
}

pub fn is_empty_intersection(r1 gg.Rect, r2 gg.Rect) bool {
	r := intersection_rect(r1, r2)
	return r.width < 0 || r.height < 0
}

pub fn union_rect(r1 gg.Rect, r2 gg.Rect) gg.Rect {
	// top left and bottom right points
	tl_x, tl_y := math.min(r1.x, r2.x), math.min(r1.y, r2.y)
	br_x, br_y := math.max(r1.x + r1.width, r2.x + r2.width), math.max(r1.y + r1.height,
		r2.y + r2.height)
	// intersection
	r := gg.Rect{f32(tl_x), f32(tl_y), f32(br_x - tl_x), f32(br_y - tl_y)}
	return r
}

pub fn inside_rect(r gg.Rect, c gg.Rect) bool { // c for container
	return r.x >= c.x && r.y >= c.y && r.x + r.width <= c.x + c.width
		&& r.y + r.height <= c.y + c.height
}

pub fn is_rgb_valid(c int) bool {
	return if c >= 0 && c < 256 { true } else { false }
}

// Color
type HexColor = string

pub fn hex_rgba(r u8, g u8, b u8, a u8) string {
	return '#${r.hex()}${g.hex()}${b.hex()}${a.hex()}'
}

pub fn hex_color(c gx.Color) string {
	return '#${c.r.hex()}${c.g.hex()}${c.b.hex()}${c.a.hex()}'
}

pub fn (hs HexColor) rgba() (u8, u8, u8, u8) {
	u := ('0x' + hs[1..]).u32()
	return u8(u >> 24), u8(u >> 16), u8(u >> 8), u8(u)
}

pub fn (hs HexColor) color() gx.Color {
	u := ('0x' + hs[1..]).u32()
	return gx.rgba(u8(u >> 24), u8(u >> 16), u8(u >> 8), u8(u))
}

pub fn alpha_colored(c gx.Color, a u8) gx.Color {
	return gx.rgba(c.r, c.g, c.b, a)
}
