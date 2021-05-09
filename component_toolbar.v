module ui

[heap]
struct ToolBar {
pub mut:
	layout &Stack // optional
	items  []Widget
	// To become a component of a parent component
	component voidptr
}

pub struct ToolBarConfig {
	id       string
	widths   Size
	heights  Size
	spacing  f64 // Size = Size(0.) // Spacing = Spacing(0) // int
	spacings []f64 = []f64{}
	items    []Widget
}

pub fn toolbar(c ToolBarConfig) &Stack {
	mut layout := row({
		id: c.id
		widths: c.widths
		heights: c.heights
		spacing: c.spacing
		spacings: c.spacings
	}, c.items)
	tb := &ToolBar{
		layout: layout
		items: c.items
	}
	for mut child in c.items {
		if mut child is Button {
			child.component = tb
		} else if mut child is Label {
			child.component = tb
		} else if mut child is Rectangle {
			child.component = tb
		}
	}
	return layout
}
