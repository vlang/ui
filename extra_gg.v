module ui

import gg
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
