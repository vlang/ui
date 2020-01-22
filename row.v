
module ui

pub struct RowConfig {
	height  int
	alignment VerticalAlignment
	spacing int
	stretch bool
	margin	MarginConfig
}

pub fn row(c RowConfig, children []IWidgeter) &Stack {
	return stack({
		height: c.height
		vertical_alignment: c.alignment
		spacing: c.spacing
		stretch: c.stretch
		direction: .row
		margin: c.margin
	}, children)
}