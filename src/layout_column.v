// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx

[params]
pub struct ColumnParams {
	id        string
	width     int // To remove soon
	height    int // To remove soon
	alignment HorizontalAlignment
	spacing   f64 // Size = Size(0.0) // Spacing = Spacing(0) // int
	spacings  []f64 = []f64{}
	stretch   bool // to remove ui.stretch doing the job from parent
	margin    Margin
	margin_   f64
	// children related
	widths     Size //[]f64 // children sizes
	heights    Size //[]f64
	alignments HorizontalAlignments
	align      Alignments
	bg_color   gx.Color = no_color
	bg_radius  f64
	title      string
	scrollview bool
	clipping   bool
	children   []Widget
}

pub fn column(c ColumnParams) &Stack {
	return stack(
		id: c.id
		height: c.height
		width: c.width
		horizontal_alignment: c.alignment
		spacings: spacings(c.spacing, c.spacings, c.children.len - 1)
		stretch: c.stretch
		direction: .column
		margins: margins(c.margin_, c.margin)
		heights: c.heights.as_f32_array(c.children.len) //.map(f32(it))
		widths: c.widths.as_f32_array(c.children.len) //.map(f32(it))
		horizontal_alignments: c.alignments
		align: c.align
		bg_color: c.bg_color
		bg_radius: f32(c.bg_radius)
		title: c.title
		scrollview: c.scrollview
		clipping: c.clipping
		children: c.children
	)
}
