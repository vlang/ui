module ui

import math

struct Rect {
pub:
	x int
	y int
	w int
	h int
}

// return the ui.Rect which is the intersection of this and the other ui.Rect
pub fn (r Rect) intersection(o Rect) Rect {
	// top left and bottom right points
	x1, y1 := math.max(r.x, o.x), math.max(r.y, o.y)
	x2, y2 := math.min(r.x + r.w, o.x + o.w), math.min(r.y + r.h, o.y + o.h)
	// intersection
	return Rect{x1, y1, math.max(0, x2 - x1), math.max(0, y2 - y1)}
}

// test if this ui.Rect is empty
pub fn (r Rect) is_empty() bool {
	return r.w <= 0 || r.h <= 0
}

// return the smallest ui.Rect which contains both this and the other ui.Rect
pub fn (r Rect) combine(o Rect) Rect {
	if o.is_empty() {
		return r
	}
	if r.is_empty() {
		return o
	}
	// top left and bottom right points
	x1, y1 := math.min(r.x, o.x), math.min(r.y, o.y)
	x2, y2 := math.max(r.x + r.w, o.x + o.w), math.max(r.y + r.h, o.y + o.h)
	// smallest containing rect
	return Rect{x1, y1, math.max(0, x2 - x1), math.max(0, y2 - y1)}
}

// returns true if this ui.Rect contains the other ui.Rect
pub fn (r Rect) contains_rect(o Rect) bool {
	return r.x <= o.x && r.y <= o.y && r.x + r.w >= o.x + o.w && r.y + r.h >= o.y + o.h
}
