// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a MIT license
// that can be found in the LICENSE file.
module ui

import math

pub enum VerticalAlignment {
	top = 0
	center
	bottom
}

pub enum HorizontalAlignment {
	left = 0
	center
	right
}

pub struct HorizontalAlignments {
pub:
	left   []int
	center []int
	right  []int
}

pub struct VerticalAlignments {
pub:
	top    []int
	center []int
	bottom []int
}

// Anticipating replacement of VerticalAlignments
pub struct Alignments {
pub:
	center       []int
	left_top     []int
	top          []int
	right_top    []int
	right        []int
	right_bottom []int
	bottom       []int
	left_bottom  []int
	left         []int
}

pub fn get_align_offset_from_parent(mut w Widget, aw f64, ah f64) (int, int) {
	width, height := w.size()
	parent := w.parent
	parent_width, parent_height := if parent is Stack { parent.free_size() } else { parent.size() }
	dw := math.max(parent_width - width, 0)
	dh := math.max(parent_height - height, 0)
	$if get_align ? {
		if w.id in env('UI_IDS').split(',') {
			println('align: ${w.id} int(${aw} * ${dw}), int(${ah} * ${dh})')
			println('${width}, ${height} ${parent_width}, ${parent_height}')
		}
	}
	return int(aw * dw), int(ah * dh)
}

pub fn get_align_offset_from_size(width int, height int, pwidth int, pheight int, aw f64, ah f64) (int, int) {
	dw := math.max(pwidth - width, 0)
	dh := math.max(pheight - height, 0)
	return int(aw * dw), int(ah * dh)
}
