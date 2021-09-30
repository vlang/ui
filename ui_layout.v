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
