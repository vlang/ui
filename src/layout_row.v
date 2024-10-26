// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a MIT license
// that can be found in the LICENSE file.
module ui

import gx

@[params]
pub struct RowParams {
pub:
	id        string
	width     int
	height    int
	alignment VerticalAlignment
	spacing   f64
	spacings  []f64 = []f64{} // Size = Size(0.0) // Spacing = Spacing(0) // int
	stretch   bool
	margin_   f64
	margin    Margin
	// children related
	widths     Size //[]f64 // children sizes
	heights    Size //[]f64
	align      Alignments
	alignments VerticalAlignments
	bg_color   gx.Color = no_color
	bg_radius  f64
	title      string
	scrollview bool
	clipping   bool
	children   []Widget
	hidden     bool
}

pub fn row(c RowParams) &Stack {
	return stack(
		id:                  c.id
		height:              c.height
		width:               c.width
		vertical_alignment:  c.alignment
		spacings:            spacings(c.spacing, c.spacings, c.children.len - 1)
		stretch:             c.stretch
		direction:           .row
		margins:             margins(c.margin_, c.margin)
		widths:              c.widths.as_f32_array(c.children.len) //.map(f32(it))
		heights:             c.heights.as_f32_array(c.children.len) //.map(f32(it))
		vertical_alignments: c.alignments
		align:               c.align
		bg_color:            c.bg_color
		bg_radius:           f32(c.bg_radius)
		title:               c.title
		scrollview:          c.scrollview
		clipping:            c.clipping
		children:            c.children
		// hidden: c.hidden
	)
}
