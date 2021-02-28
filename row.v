// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

pub struct RowConfig {
pub:
	width     int
	height    int
	alignment VerticalAlignment
	spacing   f64
	spacings  []f64 = []f64{} // Size = Size(0.) // Spacing = Spacing(0) // int
	stretch   bool
	margin    f64
	margins   Margins
	// children related
	widths     Size //[]f64 // children sizes
	heights    Size //[]f64
	align      Alignments
	alignments VerticalAlignments
}

pub fn row(c RowConfig, children []Widget) &Stack {
	return stack({
		height: c.height
		width: c.width
		vertical_alignment: c.alignment
		spacings: spacings(c.spacing, c.spacings, children.len - 1)
		stretch: c.stretch
		direction: .row
		margins: margins(c.margin, c.margins)
		widths: c.widths.as_f32_array(children.len) //.map(f32(it))
		heights: c.heights.as_f32_array(children.len) //.map(f32(it))
		vertical_alignments: c.alignments
		align: c.align
	}, children)
}
