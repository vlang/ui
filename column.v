// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

pub struct ColumnConfig {
	width     int // To remove soon
	height    int // To remove soon
	alignment HorizontalAlignment
	spacing   f64 // Size = Size(0.) // Spacing = Spacing(0) // int
	spacings  []f64 = []f64{}
	stretch   bool
	margin    MarginConfig
	// children related
	widths     Size //[]f64 // children sizes
	heights    Size //[]f64
	alignments HorizontalAlignments
	align      Alignments
}

pub fn column(c ColumnConfig, children []Widget) &Stack {
	mut spacing := [f32(c.spacing)].repeat(children.len - 1)
	if c.spacings.len == children.len - 1 {
		spacing = c.spacings.map(f32(it))
	}
	return stack({
		height: c.height
		width: c.width
		horizontal_alignment: c.alignment
		spacing: spacing // c.spacing.as_f32_array(children.len - 1) // c.spacing.as_int_array(children.len - 1)
		stretch: c.stretch
		direction: .column
		margin: c.margin.as_margin()
		heights: c.heights.as_f32_array(children.len) //.map(f32(it))
		widths: c.widths.as_f32_array(children.len) //.map(f32(it))
		horizontal_alignments: c.alignments
		align: c.align
	}, children)
}
