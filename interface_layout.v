// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import eventbus

pub interface Layout {
	id string
	get_ui() &UI
	get_state() voidptr
	size() (int, int)
	get_children() []Widget
	get_subscriber() &eventbus.Subscriber
mut:
	resize(w int, h int)
	update_layout()
	draw()
}

pub fn (l &Layout) set_children_z_index(z_index int) {
	for mut child in l.get_children() {
		if child is Layout {
			l2 := child as Layout
			l2.set_children_z_index(z_index)
		}
		child.z_index = z_index
	}
}

pub fn (l &Layout) incr_children_z_index(z_inc int) {
	// println("incr_children_z_index $l.id z_inc=$z_inc")
	for mut child in l.get_children() {
		if child is Layout {
			l2 := child as Layout
			l2.incr_children_z_index(z_inc)
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

//---- Layout focusable methods

pub fn (layout Layout) unfocus_all() {
	// println('window.unfocus_all()')
	for mut child in layout.get_children() {
		if child is Layout {
			l := child as Layout
			l.unfocus_all()
		} else if child is Focusable {
			mut f := child as Focusable
			f.unfocus()
		}
	}
}

pub fn (layout Layout) set_focus_next() bool {
	mut focused_found := false
	mut window := layout.get_ui().window
	for mut child in layout.get_children() {
		$if focus ? {
			println('child to focus_next $child.id() ${child is Focusable}  ')
		}
		focused_found = if child is Layout {
			l := child as Layout
			l.set_focus_next()
		} else {
			false
		}
		if focused_found {
			break
		}
		if child is Focusable {
			mut f := child as Focusable
			if f.has_focusable() {
				// Focus on the next widget
				if window.do_focus {
					f.focus()
					focused_found = true
					window.do_focus = false
					break
				} else {
					window.do_focus = f.is_focused
				}
			}
		}
	}
	return focused_found
}

pub fn (layout Layout) set_focus_prev() bool {
	mut focused_found := false
	mut window := layout.get_ui().window
	for mut child in layout.get_children().reverse() {
		$if focus ? {
			println('child to focus_prev $child.id() $child.type_name() ${child is Focusable}')
		}
		focused_found = if child is Layout {
			l := child as Layout
			l.set_focus_prev()
		} else {
			false
		}
		if focused_found {
			break
		}
		if child is Focusable {
			mut f := child as Focusable
			if f.has_focusable() {
				// Focus on the next widget
				if window.do_focus {
					f.focus()
					focused_found = true
					window.do_focus = false
					break
				} else {
					window.do_focus = f.is_focused
				}
			}
		}
	}
	return focused_found
}

pub fn (layout Layout) set_focus_first() bool {
	mut doit := false
	for child in layout.get_children() {
		doit = if child is Layout {
			l := child as Layout
			l.set_focus_first()
		} else if child is Focusable {
			mut f := child as Focusable
			if f.has_focusable() {
				// Focus on the next widget
				f.focus()
				true
			} else {
				false
			}
		} else {
			false
		}
		if doit {
			break
		}
	}
	return doit
}

pub fn (layout Layout) set_focus_last() bool {
	mut doit := false
	for child in layout.get_children().reverse() {
		doit = if child is Layout {
			l := child as Layout
			l.set_focus_last()
		} else if child is Focusable {
			mut f := child as Focusable
			if f.has_focusable() {
				// Focus on the next widget
				f.focus()
				true
			} else {
				false
			}
		} else {
			false
		}
		if doit {
			break
		}
	}
	return doit
}
