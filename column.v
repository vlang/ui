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
	stretch   bool // to remove ui.stretch doing the job from parent
	margin    Margin
	margin_   f64
	// children related
	widths     Size //[]f64 // children sizes
	heights    Size //[]f64
	alignments HorizontalAlignments
	align      Alignments
}

pub fn column(c ColumnConfig, children []Widget) &Stack {
	return stack({
		height: c.height
		width: c.width
		horizontal_alignment: c.alignment
		spacings: spacings(c.spacing, c.spacings, children.len - 1)
		stretch: c.stretch
		direction: .column
		margins: margins(c.margin_, c.margin)
		heights: c.heights.as_f32_array(children.len) //.map(f32(it))
		widths: c.widths.as_f32_array(children.len) //.map(f32(it))
		horizontal_alignments: c.alignments
		align: c.align
	}, children)
}
