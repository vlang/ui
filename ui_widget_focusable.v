module ui

// Contains all the methods related to focus management
// that is to say:
// * Focusable interface and its methods
// * methods for Window
// * methods for Layout interface

interface Focusable {
	ui &UI
mut:
	hidden bool
	is_focused bool
	focus()
	unfocus()
}

pub fn (w Focusable) has_focusable() bool {
	mut read_only := false
	if w is TextBox {
		read_only = w.read_only
	}
	return !read_only && !w.hidden
}

// Only one widget can have the focus inside a Window
pub fn (mut f Focusable) set_focus() {
	w := f.ui.window
	if w.locked_focus {
		return
	}
	if f.is_focused {
		$if focus ? {
			println('$f.id already has focus at $w.ui.gg.frame')
		}
		return
	}
	Layout(w).unfocus_all()
	if f.has_focusable() {
		f.is_focused = true
		$if focus ? {
			println('$f.id has focus at $w.ui.gg.frame')
		}
	}
}

//
fn (mut w Window) focus_next() {
	w.do_focus = false
	if !Layout(w).set_focus_next() {
		Layout(w).set_focus_first()
	}
}

fn (mut w Window) focus_prev() {
	w.do_focus = false
	if !Layout(w).set_focus_prev() {
		Layout(w).set_focus_last()
	}
}

pub fn (mut w Window) lock_focus() {
	w.locked_focus = true
}

pub fn (mut w Window) unlock_focus() {
	w.locked_focus = false
}

// Layout focusable methods

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
			println('child to focus_next $child.id() $child.type_name() $child.is_focusable()')
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
			println('child to focus_next $child.id() $child.type_name() $child.is_focusable()')
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
