module ui

const (
	idx_btn = typeof(button()).idx
	idx_cb  = typeof(checkbox()).idx
	idx_dd  = typeof(dropdown()).idx
	idx_lb  = typeof(listbox()).idx
	idx_rad = typeof(radio()).idx
	idx_sl  = typeof(slider()).idx
	idx_sw  = typeof(switcher()).idx
	idx_tb  = typeof(textbox()).idx
)

struct TimeWidget {
pub mut:
	w Widget
	t u64
}

// Widget having a field is_focused
pub fn (w Widget) is_focusable() bool {
	// is_focusable_type := w.type_name() in ['ui.Button', 'ui.CheckBox', 'ui.Dropdown', 'ui.ListBox',
	// 	'ui.Radio', 'ui.Slider', 'ui.Switch', 'ui.TextBox']
	is_focusable_type := w.type_idx() in [ui.idx_btn, ui.idx_cb, ui.idx_dd, ui.idx_lb, ui.idx_rad,
		ui.idx_sl, ui.idx_sw, ui.idx_tb]
	mut read_only := false
	if w is TextBox {
		read_only = w.read_only
	}
	return is_focusable_type && !read_only && !w.hidden
}

pub fn (mut w Window) lock_focus() {
	w.locked_focus = true
}

pub fn (mut w Window) unlock_focus() {
	w.locked_focus = false
}

// Only one widget can have the focus inside a Window
pub fn set_focus<T>(w &Window, mut f T) {
	if w.locked_focus {
		return
	}
	if f.is_focused() {
		$if focus ? {
			println('$f.id already has focus at $w.ui.gg.frame')
		}
		return
	}
	w.unfocus_all()
	if Widget(f).is_focusable() {
		f.is_focused = true
		$if focus ? {
			println('$f.id has focus at $w.ui.gg.frame')
		}
	}
}

pub fn set_focus_next<T>(mut w T) bool {
	mut focused_found := false
	mut window := w.ui.window
	for mut child in w.children {
		$if focus ? {
			println('child to focus_next ${widget_id(*child)} $child.type_name() $child.is_focusable()')
		}
		focused_found = if mut child is Stack {
			// $if focus ? {
			// 	println("focus next inside $child.id")
			// }
			set_focus_next(mut child)
		} else if mut child is CanvasLayout {
			// $if focus ? {
			// 	println("focus next inside $child.id")
			// }
			set_focus_next(mut child)
		} else if mut child is Group {
			// $if focus ? {
			// 	println("focus next inside $child.id")
			// }
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
		$if focus ? {
			println('child to focus_prev ${widget_id(*child)} $child.type_name() $child.is_focusable()')
		}
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

/*
All this stuff is a future development

interface Focusable {
	hidden bool
	focus()
	is_focused() bool
}

fn (w Widget) focusable() (bool, Focusable) {
	if w is Button {
		return true, w
	} else if w is CheckBox {
		return true, w
	} else if w is Dropdown {
		return true, w
	} else if w is ListBox {
		return true, w
	} else if w is Radio {
		return true, w
	} else if w is Slider {
		return true, w
	} else if w is Switch {
		return true, w
	} else if w is TextBox {
		return true, w
	} else {
		return false, empty_stack
	}
}*/

/*
mut win := w
	t := win.ui.gg.frame
	println("here")
	if win.focusable_widgets.len == 0 {
		println("here2")
		win.focusable_widgets << TimeWidget{w: f, t: t}
		println("here3")
	} else {
		fw := win.focusable_widgets[win.focusable_widgets.len - 1]
		println("here4: $fw.t == $t")
		if fw.t == t {
			println("h4")
			win.focusable_widgets << TimeWidget{f, t}
		}
		println("h5")
	}
	//
	println("f_w: $w.focusable_widgets.len ${w.focusable_widgets.map(it.t)} ${w.focusable_widgets.map(widget_id(it.w))} ${w.focusable_widgets.map(it.w.z_index)}")
*/
