// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

pub struct ColumnConfig {
	width     f32 // To remove soon
	height    f32 // To remove soon
	alignment HorizontalAlignment
	spacing   Spacing = Spacing(0) // int
	stretch   bool
	margin    MarginConfig
	// children related
	widths     Size    //[]f64 // children sizes
	heights    Size //[]f64
	alignments HorizontalAlignments
}

pub fn column(c ColumnConfig, children []Widget) &Stack {
	return stack({
		height: c.height
		width: c.width
		heights: c.heights.as_f32_array(children.len) //.map(f32(it))
		widths: c.widths.as_f32_array(children.len) //.map(f32(it))
		horizontal_alignment: c.alignment
		horizontal_alignments: c.alignments
		spacing: c.spacing.as_int_array(children.len - 1)
		stretch: c.stretch
		direction: .column
		margin: c.margin.as_margin()
	}, children)
}
