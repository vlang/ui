// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a MIT license
// that can be found in the LICENSE file.
module ui

import eventbus

pub interface Layout {
	id string
	get_ui() &UI
	size() (int, int)
	get_children() []Widget
	get_subscriber() &eventbus.Subscriber[string]
mut:
	resize(w int, h int)
	update_layout()
	draw()
}

pub fn (l Layout) as_widget() Widget {
	return if l is Widget {
		w := l as Widget
		w
	} else {
		Widget(empty_stack)
	}
}

// TODO: documentation
pub fn (l &Layout) set_children_depth(z_index int) {
	for mut child in l.get_children() {
		if mut child is Layout {
			l2 := child as Layout
			l2.set_children_depth(z_index)
		}
		child.z_index = z_index
	}
}

// TODO: documentation
pub fn (l &Layout) incr_children_depth(z_inc int) {
	// println("incr_children_depth $l.id z_inc=$z_inc")
	for mut child in l.get_children() {
		if mut child is Layout {
			l2 := child as Layout
			l2.incr_children_depth(z_inc)
		}
		// println("child $child.id z_index +($z_inc)")
		child.z_index += z_inc
	}
}

// TODO: documentation
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

// TODO: documentation
pub fn (mut l Layout) activate() {
	if mut l is Stack {
		l.deactivated = false
	} else if mut l is CanvasLayout {
		l.deactivated = false
	} else if mut l is BoxLayout {
		l.deactivated = false
	}
}

// TODO: documentation
pub fn (mut l Layout) deactivate() {
	if mut l is Stack {
		l.deactivated = true
	} else if mut l is CanvasLayout {
		l.deactivated = true
	} else if mut l is BoxLayout {
		l.deactivated = true
	}
}

// TODO: documentation
pub fn (l &Layout) has_child(widget &Widget) bool {
	return l.has_child_id(widget.id)
}

//---- Layout focusable methods

// TODO: documentation
pub fn (layout Layout) unfocus_all() {
	// println('window.unfocus_all()')
	for mut child in layout.get_children() {
		if mut child is Layout {
			l := child as Layout
			l.unfocus_all()
		} else if mut child is Focusable {
			mut f := child as Focusable
			f.unfocus()
		}
	}
}

// TODO: documentation
pub fn (layout Layout) set_focus_next() bool {
	mut focused_found := false
	mut window := layout.get_ui().window
	for mut child in layout.get_children() {
		$if focus ? {
			println('child to focus_next ${child.id()} ${child is Focusable}  ')
		}
		focused_found = if mut child is Layout {
			l := child as Layout
			l.set_focus_next()
		} else {
			false
		}
		if focused_found {
			break
		}
		if mut child is Focusable {
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

// TODO: documentation
pub fn (layout Layout) set_focus_prev() bool {
	mut focused_found := false
	mut window := layout.get_ui().window
	for mut child in layout.get_children().reverse() {
		$if focus ? {
			println('child to focus_prev ${child.id()} ${child.type_name()} ${child is Focusable}')
		}
		focused_found = if mut child is Layout {
			l := child as Layout
			l.set_focus_prev()
		} else {
			false
		}
		if focused_found {
			break
		}
		if mut child is Focusable {
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

// TODO: documentation
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

// TODO: documentation
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

// TODO: documentation
pub fn (l Layout) has_scrollview() bool {
	if l is ScrollableWidget {
		sw := l as ScrollableWidget
		return has_scrollview(sw)
	} else {
		return false
	}
}

// TODO: documentation
pub fn (l Layout) has_scrollview_or_parent_scrollview() bool {
	if l is ScrollableWidget {
		sw := l as ScrollableWidget
		return has_scrollview_or_parent_scrollview(sw)
	} else {
		return false
	}
}

// Debug function to explore the tree of children
pub fn (l Layout) debug_show_children_tree(level int) {
	if level == 0 {
		println('_'.repeat(80))
		if l is Stack {
			println('${' '.repeat(level)} root Stack ${l.id} ${l.size()}')
		}
	}
	for i, mut child in l.get_children() {
		println('${' '.repeat(level)} ${level}:${i} -> ${child.id} (${child.type_name()}) (${child.x}, ${child.y}) ${child.size()} z_index: ${child.z_index}')
		if mut child is Layout {
			c := child as Layout
			c.debug_show_children_tree(level + 1)
		}
	}
}

// TODO: documentation
pub fn (mut l Layout) update_drawing_children() {
	if mut l is CanvasLayout {
		l.set_drawing_children()
	} else if mut l is CanvasLayout {
		l.set_drawing_children()
	}
}
