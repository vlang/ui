// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
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
	init(Layout)
	cleanup()
	draw()
	point_inside(x f64, y f64) bool
	set_pos(x int, y int)
	propose_size(w int, h int) (int, int)
	size() (int, int)
	set_visible(bool)
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
