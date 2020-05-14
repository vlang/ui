
module ui

pub struct RowConfig {
pub:
	height  int
	alignment VerticalAlignment
	spacing int
	stretch bool
	margin	MarginConfig
	children []Widget
}

pub fn row(c RowConfig, children []Widget) &Stack {
	return stack({
		height: c.height
		vertical_alignment: c.alignment
		spacing: c.spacing
		stretch: c.stretch
		direction: .row
		margin: c.margin
	}, children)
}

pub fn row2(c RowConfig) &Stack {
	return stack({
		height: c.height
		vertical_alignment: c.alignment
		spacing: c.spacing
		stretch: c.stretch
		direction: .row
		margin: c.margin
	}, c.children)
}
