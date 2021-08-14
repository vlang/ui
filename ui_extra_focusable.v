module ui

// Widget having a field is_focused
pub fn (w Widget) is_focusable() bool {
	is_focusable_type := w.type_name() in ['ui.Button', 'ui.CanvasLayout', 'ui.CheckBox',
		'ui.Dropdown', 'ui.ListBox', 'ui.Radio', 'ui.Slider', 'ui.Switch', 'ui.TextBox']
	mut read_only := false
	if w is TextBox {
		read_only = w.read_only
	}
	return is_focusable_type && !read_only
}

// Only one widget can have the focus inside a Window
pub fn set_focus<T>(w &Window, mut f T) {
	if f.is_focused() {
		return
	}
	w.unfocus_all()
	if Widget(f).is_focusable() {
		f.is_focused = true
		println('$f.id has focus')
	}
}

pub fn set_focus_next<T>(mut w T) bool {
	mut focused_found := false
	mut window := w.ui.window
	for mut child in w.children {
		// println("child to focus_next ${widget_id(*child)} ${child.type_name()} ${child.is_focusable()}")
		focused_found = if mut child is Stack {
			// println("focus next inside $child.id")
			set_focus_next(mut child)
		} else if mut child is CanvasLayout {
			// println("focus next inside $child.id")
			set_focus_next(mut child)
		} else if mut child is Group {
			// println("focus next inside $child.id")
			set_focus_next(mut child)
		} else {
			false
		}
		if focused_found {
			break
		}
		if child.is_focusable() {
			// Focus on the next widget
			if window.do_focus {
				child.focus()
				focused_found = true
				window.do_focus = false
				break
			} else {
				window.do_focus = child.is_focused()
			}
		}
	}
	return focused_found
}

pub fn set_focus_prev<T>(mut w T) bool {
	mut focused_found := false
	mut window := w.ui.window
	for mut child in w.children.reverse() {
		// println("child to focus_prev ${widget_id(*child)} ${child.type_name()} ${child.is_focusable()}")
		focused_found = if mut child is Stack {
			// println("focus next inside $child.id")
			set_focus_prev(mut child)
		} else if mut child is CanvasLayout {
			// println("focus next inside $child.id")
			set_focus_prev(mut child)
		} else if mut child is Group {
			// println("focus next inside $child.id")
			set_focus_prev(mut child)
		} else {
			false
		}
		if focused_found {
			break
		}
		if child.is_focusable() {
			// Focus on the next widget
			if window.do_focus {
				child.focus()
				focused_found = true
				window.do_focus = false
				break
			} else {
				window.do_focus = child.is_focused()
			}
		}
	}
	return focused_found
}

pub fn set_focus_first<T>(mut w T) bool {
	mut doit := false
	for mut child in w.children {
		doit = if mut child is Stack {
			set_focus_first(mut child)
		} else if mut child is CanvasLayout {
			set_focus_first(mut child)
		} else if mut child is Group {
			set_focus_first(mut child)
		} else if child.is_focusable() {
			// Focus on the next widget
			child.focus()
			true
		} else {
			false
		}
		if doit {
			break
		}
	}
	return doit
}

pub fn set_focus_last<T>(mut w T) bool {
	mut doit := false
	for mut child in w.children.reverse() {
		doit = if mut child is Stack {
			set_focus_last(mut child)
		} else if mut child is CanvasLayout {
			set_focus_last(mut child)
		} else if mut child is Group {
			set_focus_last(mut child)
		} else if child.is_focusable() {
			// Focus on the next widget
			child.focus()
			true
		} else {
			false
		}
		if doit {
			break
		}
	}
	return doit
}
