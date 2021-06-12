module ui

pub fn get_depth(w &Widget) int {
	return w.z_index
}

pub fn set_depth(mut w Widget, z_index int) {
	w.z_index = z_index
}