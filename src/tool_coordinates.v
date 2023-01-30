module ui

// allow to specify widgets with absolute coordinates (CanvasLayout and Window)
pub fn at(x int, y int, w Widget) Widget {
	mut w2 := w
	w2.x, w2.y = x, y
	return w2
}

// on top_layer
pub fn on_top_at(x int, y int, w Widget) Widget {
	mut w2 := w
	w2.x, w2.y = x, y
	w2.id = w2.id + id_append_top_layer // to detect
	return w2
}

fn offset_start(mut w Widget) {
	w.x += w.offset_x
	w.y += w.offset_y
}

fn offset_end(mut w Widget) {
	w.x -= w.offset_x
	w.y -= w.offset_y
}

//**** offset ****

// set offset_x and offset_y for Widget
pub fn set_offset(mut w Widget, ox int, oy int) {
	w.offset_x, w.offset_y = ox, oy
	if mut w is Layout {
		for mut child in w.get_children() {
			set_offset(mut child, ox, oy)
		}
	}
	// if mut w is Stack {
	//	for mut child in w.children {
	//		set_offset(mut child, ox, oy)
	//	}
	//} else if mut w is Group {
	//	for mut child in w.children {
	//		set_offset(mut child, ox, oy)
	//	}
	//} else if mut w is CanvasLayout {
	//	for mut child in w.children {
	//		set_offset(mut child, ox, oy)
	//	}
	//}
}
