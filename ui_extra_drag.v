module ui

// child_to_drag(w Widget) ??? Widget would needs method is_draggable
fn drag_register(w Widget, ui &UI, e &MouseEvent) {
	if shift_key(e.mods) {
		$if drag ? {
			println('drag ${typeof(w).name}')
		}
		mut window := ui.window
		if window.drag_activated {
			if w.z_index > window.drag_widget.z_index {
				window.drag_widget = w
				window.drag_start_x = e.x - w.offset_x
				window.drag_start_y = e.y - w.offset_y
				// println('drag: ($e.x, $e.y, ${window.drag_start_x},${window.drag_start_y})')
			}
		} else {
			window.drag_activated = true
			window.drag_widget = w
			window.drag_start_x = e.x - w.offset_x
			window.drag_start_y = e.y - w.offset_y
			// println('drag: ($e.x, $e.y, ${window.drag_start_x},${window.drag_start_y})')
		}
	}
}

fn drag_child(window Window, x f64, y f64) {
	mut w := window.drag_widget
	w.offset_x = int(x - window.drag_start_x)
	w.offset_y = int(y - window.drag_start_y)
}

fn drop_child(mut window Window) {
	$if drag ? {
		w := window.drag_widget
		println('drop $w.type_name()')
	}
	window.drag_activated = false
}
