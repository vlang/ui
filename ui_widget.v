module ui

pub fn get_depth(w &Widget) int {
	return w.z_index
}

pub fn set_depth(mut w Widget, z_index int) {
	w.z_index = z_index
	// w.set_visible(z_index != ui.z_index_hidden)
}

pub fn (child &Widget) id() string {
	return child.id
}

pub fn (w &Window) is_registred(widget &Widget) bool {
	return widget.id in w.widgets
}
