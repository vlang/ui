module ui

import time
import gg

pub interface Draggable {
	id string
	x  int
	y  int
	size() (int, int)
	get_window() &Window
	drag_type() string
	drag_bounds() gg.Rect
mut:
	offset_x int
	offset_y int
	z_index  int
	draw()
}

// TODO: documentation
pub fn (w Draggable) active() bool {
	d := w.get_window().dragger
	return w == d.widget
}

// TODO: documentation
pub fn (w Draggable) bounds() gg.Rect {
	sw, sh := w.size()
	return gg.Rect{w.x, w.y, sw, sh}
}

// TODO: documentation
pub fn (w Draggable) scaled_bounds() gg.Rect {
	sw, sh := w.size()
	sc := gg.dpi_scale()
	return gg.Rect{w.x * sc, w.y * sc, sw * sc, sh * sc}
}

// TODO: documentation
pub fn (w Draggable) inside(b gg.Rect) bool {
	return inside_rect(w.bounds(), b)
}

// TODO: documentation
pub fn (w Draggable) intersect(b gg.Rect) bool {
	// println("${w.bounds()} inter $b")
	return !is_empty_intersection(w.drag_bounds(), b)
}

//** Drag stuff ***//

struct Dragger {
pub mut:
	typ       string
	activated bool
	widget    &Draggable = button()
	start_x   f64
	start_y   f64
	pos_x     f64
	pos_y     f64
	time      time.Time
	// extra     voidptr
	extra_int int
}

/*
NB: would like external mechanism only depending on point_inside methods of Widgets
shift key (or other) to activate possible dragging
*/

fn drag_register(d &Draggable, e &MouseEvent) bool {
	if shift_key(e.mods) {
		$if drag ? {
			println('drag ${typeof(w).name}')
		}
		mut window := d.get_window()
		if window.dragger.activated {
			if d.z_index > window.dragger.widget.z_index {
				window.dragger.widget = unsafe { d }
				window.dragger.start_x = e.x - d.offset_x
				window.dragger.start_y = e.y - d.offset_y
				// println('drag: ($e.x, $e.y, ${window.dragger.start_x},${window.dragger.start_y})')
				window.dragger.pos_x = e.x
				window.dragger.pos_y = e.y
				window.dragger.time = time.now()
			}
		} else {
			window.dragger.activated = true
			window.mouse.start('blue')
			window.dragger.widget = unsafe { d }
			window.dragger.start_x = e.x - d.offset_x
			window.dragger.start_y = e.y - d.offset_y
			// println('drag: ($e.x, $e.y, ${window.dragger.start_x},${window.dragger.start_y})')
			window.dragger.pos_x = e.x
			window.dragger.pos_y = e.y
			window.dragger.time = time.now()
		}
		return true
	}
	return false
}

// fn dragger_extra(window &Window, extra voidptr) {
// 	mut d := window.dragger
// 	if d.activated {
// 		d.extra = extra
// 	}
// }

fn drag_active(window &Window) bool {
	return window.dragger.activated
}

fn draw_dragger(mut window Window) {
	if window.dragger.activated {
		window.dragger.widget.draw()
	}
}

fn drag_child(mut window Window, x f64, y f64) {
	mut w := window.dragger.widget
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

fn drag_child_dropped(mut window Window) {
	$if drag ? {
		w := window.dragger.widget
		println('drop ${w.type_name()}')
	}
	window.mouse.stop()
	window.dragger.activated = false
}

// DropZone

pub interface DropZone {
	ui &UI
	id string
	size() (int, int)
mut:
	x          int
	y          int
	drop_types []string
}

// TODO: documentation
pub fn (dz DropZone) bounds() gg.Rect {
	w, h := dz.size()
	return gg.Rect{dz.x, dz.y, w, h}
}

// TODO: documentation
pub fn (dz DropZone) drop_types() []string {
	return dz.drop_types
}

// TODO: documentation
pub fn (mut dz DropZone) set_drop_types(dt []string) {
	dz.drop_types = dt
}

// Interaction Between Dragger and DropZone

fn dragger_inside_dropzone(mut d DropZone) bool {
	dragger := d.ui.window.dragger
	if dragger.activated {
		mut w := dragger.widget
		return w.inside(d.bounds()) && w.drag_type() in d.drop_types
	} else {
		return false
	}
}

fn dragger_intersect_dropzone(mut d DropZone) bool {
	dragger := d.ui.window.dragger
	if dragger.activated {
		mut w := dragger.widget
		return w.intersect(d.bounds()) && w.drag_type() in d.drop_types
	} else {
		return false
	}
}
