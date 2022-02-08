module ui

import time
import sokol.sapp

//** move mode ***

enum CoordinateMode {
	relative
	drag // offset
}

fn offset_start(mut w Widget) {
	w.x += w.offset_x
	w.y += w.offset_y
}

fn offset_end(mut w Widget) {
	w.x -= w.offset_x
	w.y -= w.offset_y
}

//** Drag stuff ***//

struct Dragger {
pub mut:
	activated bool
	widget    Widget = empty_stack
	start_x   f64
	start_y   f64
	pos_x     f64
	pos_y     f64
	time      time.Time
}

/*
NB: would like external mechanism only depending on point_inside methods of Widgets
shift key (or other) to activate possible dragging
*/

fn drag_register(w Widget, ui &UI, e &MouseEvent) {
	if shift_key(e.mods) {
		$if drag ? {
			println('drag ${typeof(w).name}')
		}
		mut window := ui.window
		if window.dragger.activated {
			if w.z_index > window.dragger.widget.z_index {
				window.dragger.widget = w
				window.dragger.start_x = e.x - w.offset_x
				window.dragger.start_y = e.y - w.offset_y
				// println('drag: ($e.x, $e.y, ${window.dragger.start_x},${window.dragger.start_y})')
				window.dragger.pos_x = e.x
				window.dragger.pos_y = e.y
				window.dragger.time = time.now()
			}
		} else {
			window.dragger.activated = true
			window.dragger.widget = w
			window.dragger.start_x = e.x - w.offset_x
			window.dragger.start_y = e.y - w.offset_y
			// println('drag: ($e.x, $e.y, ${window.dragger.start_x},${window.dragger.start_y})')
			window.dragger.pos_x = e.x
			window.dragger.pos_y = e.y
			window.dragger.time = time.now()
		}
	}
}

fn drag_child(mut window Window, x f64, y f64) {
	mut w := window.dragger.widget
	sapp.show_mouse(false)
	$if speed ? {
		t := time.now()
		speed := 0.1
		dt := (t - window.dragger.time).milliseconds() * speed
		window.dragger.time = t

		dx := (x - window.dragger.pos_x) / dt
		dy := (y - window.dragger.pos_y) / dt
		// println("dt=$dt dx=$dx dy=$dy")

		w.offset_x = int(x + dx - window.dragger.start_x)
		w.offset_y = int(y + dy - window.dragger.start_y)

		window.dragger.pos_x = x
		window.dragger.pos_y = y
	} $else {
		w.offset_x = int(x - window.dragger.start_x)
		w.offset_y = int(y - window.dragger.start_y)
	}
}

fn drop_child(mut window Window) {
	$if drag ? {
		w := window.dragger.widget
		println('drop $w.type_name()')
	}
	sapp.show_mouse(true)
	window.dragger.activated = false
}

//**** offset ****

// set offset_x and offset_y for Widget
pub fn set_offset(mut w Widget, ox int, oy int) {
	w.offset_x, w.offset_y = ox, oy
	if mut w is Stack {
		for mut child in w.children {
			set_offset(mut child, ox, oy)
		}
	} else if mut w is Group {
		for mut child in w.children {
			set_offset(mut child, ox, oy)
		}
	} else if mut w is CanvasLayout {
		for mut child in w.children {
			set_offset(mut child, ox, oy)
		}
	}
}

// allow to specify widgets with absolute coordinates (CanvasLayout and Window)
pub fn at(x int, y int, w Widget) Widget {
	mut w2 := w
	w2.x, w2.y = x, y
	return w2
}
