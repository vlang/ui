// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

pub struct RowConfig {
pub:
	width     f32
	height    f32
	alignment VerticalAlignment
	spacing   Spacing = Spacing(0) // int
	stretch   bool
	margin    MarginConfig
	// children related
	widths     Size //[]f64 // children sizes
	heights    Size //[]f64
	alignments VerticalAlignments
}

pub fn row(c RowConfig, children []Widget) &Stack {
	return stack({
		height: c.height
		width: c.width
		widths: c.widths.as_f32_array(children.len) //.map(f32(it))
		heights: c.heights.as_f32_array(children.len) //.map(f32(it))
		vertical_alignment: c.alignment
		vertical_alignments: c.alignments
		spacing: c.spacing.as_int_array(children.len - 1)
		stretch: c.stretch
		direction: .row
		margin: c.margin.as_margin()
	}, children)
}
