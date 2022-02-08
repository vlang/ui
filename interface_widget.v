// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

pub interface Widget {
mut:
	id string
	x int
	y int
	z_index int
	offset_x int
	offset_y int
	hidden bool
	parent Layout
	init(Layout)
	set_pos(x int, y int)
	propose_size(w int, h int) (int, int)
	size() (int, int)
	point_inside(x f64, y f64) bool
	set_visible(bool)
	draw()
	cleanup()
}

pub fn (w &Widget) get_depth() int {
	return w.z_index
}

pub fn (mut w Widget) set_depth(z_index int) {
	w.z_index = z_index
	// w.set_visible(z_index != ui.z_index_hidden)
}

pub fn (child &Widget) id() string {
	return child.id
}

// Find if there is recursively a parent deactivated (i.e. z_index <= ui.z_index_hidden)
// used in accordion component
pub fn (w &Widget) has_parent_deactivated() bool {
	p := w.parent
	if p is Stack {
		// println("hpd $w.id: $p.z_index")
		return p.z_index <= z_index_hidden || Widget(p).has_parent_deactivated()
	} else if p is CanvasLayout {
		// println("hpd $w.id: $p.z_index")
		return p.z_index <= z_index_hidden || Widget(p).has_parent_deactivated()
	} else if p is Group {
		// println("hpd $w.id: $p.z_index")
		return p.z_index <= z_index_hidden || Widget(p).has_parent_deactivated()
	}
	return false
}
