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

pub fn (l &Layout) has_child_id(widget_id string) bool {
	// println("has_child_id children: ${l.get_children().len} => ${l.get_children().map(it.id)}")
	for child in l.get_children() {
		// println("has_child:  <$child.id> == <$widget_id>")
		if child.id == widget_id {
			return true
		}
		if child is Layout {
			// println("$child.id is layout")
			l2 := child as Layout
			if l2.has_child_id(widget_id) {
				return true
			}
		}
	}
	return false
}

pub fn (l &Layout) has_child(widget &Widget) bool {
	return l.has_child_id(widget.id)
}
