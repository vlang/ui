// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

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
	left   []int
	center []int
	right  []int
}

pub struct VerticalAlignments {
	top    []int
	center []int
	bottom []int
}

// Anticipating replacement of VerticalAlignments
pub struct Alignments {
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
