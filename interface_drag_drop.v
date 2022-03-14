module ui

import time
import sokol.sapp
import gg

interface Draggable {
	id string
	x int
	y int
	size() (int, int)
	get_window() &Window
	drag_type() string
mut:
	offset_x int
	offset_y int
	z_index int
}

pub fn (w Draggable) active() bool {
	d := w.get_window().dragger
	return w == d.widget
}

pub fn (w Draggable) bounds() gg.Rect {
	sw, sh := w.size()
	return gg.Rect{w.x, w.y, sw, sh}
}

pub fn (w Draggable) scaled_bounds() gg.Rect {
	sw, sh := w.size()
	sc := gg.dpi_scale()
	return gg.Rect{w.x * sc, w.y * sc, sw * sc, sh * sc}
}

pub fn (w Draggable) inside(b gg.Rect) bool {
	return inside_rect(w.bounds(), b)
}

//** Drag stuff ***//

struct Dragger {
pub mut:
	typ		  string	 
	activated bool
	widget    Draggable = button()
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

fn drag_register(w Draggable, e &MouseEvent) bool {
	if shift_key(e.mods) {
		$if drag ? {
			println('drag ${typeof(w).name}')
		}
		mut window := w.get_window()
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
		return true
	}
	return false
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

// pub fn drop_register
