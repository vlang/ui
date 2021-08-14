module ui

pub fn get_depth(w &Widget) int {
	return w.z_index
}

pub fn set_depth(mut w Widget, z_index int) {
	w.z_index = z_index
	// w.set_visible(z_index != ui.z_index_hidden)
}

// TODO: If id is added to Widget interface,
// this could be simplified and above all extensible with external widgets
pub fn widget_id(child Widget) string {
	if child is Button {
		return child.id
	} else if child is Canvas {
		return child.id
	} else if child is CheckBox {
		return child.id
	} else if child is Dropdown {
		return child.id
	} else if child is Grid {
		return child.id
	} else if child is Label {
		return child.id
	} else if child is ListBox {
		return child.id
	} else if child is Menu {
		return child.id
	} else if child is Picture {
		return child.id
	} else if child is ProgressBar {
		return child.id
	} else if child is Radio {
		return child.id
	} else if child is Rectangle {
		return child.id
	} else if child is Slider {
		return child.id
	} else if child is Switch {
		return child.id
	} else if child is TextBox {
		return child.id
	} else if child is Transition {
		return child.id
	} else if child is Stack {
		return child.id
	} else if child is Group {
		return child.id
	} else if child is CanvasLayout {
		return child.id
	} else {
		return '_unknown'
	}
}
