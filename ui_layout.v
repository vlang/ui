module ui

fn (l &Layout) update_children_z_index(z_inc int) {
	for mut child in l.get_children() {
		if child is Layout {
			l2 := child as Layout
			l2.update_children_z_index(z_inc)
		}
		// println("child $child.id z_index +($z_inc)")
		child.z_index += z_inc
	}
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
