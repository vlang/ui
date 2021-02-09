// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

pub struct ColumnConfig {
	width      f32 // = 1
	height     f32
	alignment  HorizontalAlignment
	alignments HorizontalAlignments
	spacing    int
	stretch    bool
	margin     MarginConfig
}

pub fn column(c ColumnConfig, children []Widget) &Stack {
	return stack({
		height: c.height
		width: c.width
		horizontal_alignment: c.alignment
		horizontal_alignments: c.alignments
		spacing: c.spacing
		stretch: c.stretch
		direction: .column
		margin: c.margin
	}, children)
}
