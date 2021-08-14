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
	mut doit, mut focused_found := false, false
	for mut child in w.children {
		focused_found = if mut child is Stack {
			set_focus_next(mut child)
		} else if mut child is CanvasLayout {
			set_focus_next(mut child)
		} else if mut child is Group {
			set_focus_next(mut child)
		} else {
			false
		}
		if focused_found {
			break
		}
		if child.is_focusable() {
			// Focus on the next widget
			if doit {
				child.focus()
				focused_found = true
				break
			}
			is_focused := child.is_focused()
			if is_focused {
				doit = true
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
