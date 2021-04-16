// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx

pub struct RowConfig {
pub:
	id        string
	width     int
	height    int
	alignment VerticalAlignment
	spacing   f64
	spacings  []f64 = []f64{} // Size = Size(0.) // Spacing = Spacing(0) // int
	stretch   bool
	margin_   f64
	margin    Margin
	// children related
	widths     Size //[]f64 // children sizes
	heights    Size //[]f64
	align      Alignments
	alignments VerticalAlignments
	bg_color   gx.Color = no_color
}

pub fn row(c RowConfig, children []Widget) &Stack {
	return stack({
		id: c.id
		height: c.height
		width: c.width
		vertical_alignment: c.alignment
		spacings: spacings(c.spacing, c.spacings, children.len - 1)
		stretch: c.stretch
		direction: .row
		margins: margins(c.margin_, c.margin)
		widths: c.widths.as_f32_array(children.len) //.map(f32(it))
		heights: c.heights.as_f32_array(children.len) //.map(f32(it))
		vertical_alignments: c.alignments
		align: c.align
		bg_color: c.bg_color
	}, children)
}
