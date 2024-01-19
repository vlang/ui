// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a MIT license
// that can be found in the LICENSE file.
module ui

import gg
import gx

pub interface Widget {
mut:
	ui       &UI
	id       string
	x        int
	y        int
	z_index  int
	offset_x int
	offset_y int
	hidden   bool
	parent   Layout
	init(Layout)
	set_pos(x int, y int)
	propose_size(w int, h int) (int, int)
	size() (int, int)
	point_inside(x f64, y f64) bool
	set_visible(bool)
	draw()
	draw_device(mut d DrawDevice)
	cleanup()
}

// TODO: documentation
pub fn (w &Widget) is_visible() bool {
	return !w.hidden && w.z_index > z_index_hidden
}

// TODO: documentation
pub fn (w &Widget) is_parent_visible(recursive bool) bool {
	parent := w.parent
	if parent is Widget {
		p := parent as Widget
		if recursive {
			return p.is_visible() && p.is_parent_visible(true)
		} else {
			return p.is_visible()
		}
	} else if parent is Window {
		return true
	}
	return false
}

// TODO: documentation
pub fn (w &Widget) get_depth() int {
	return w.z_index
}

// TODO: documentation
pub fn (mut w Widget) set_depth(z_index int) {
	w.z_index = z_index
	// w.set_visible(z_index != ui.z_index_hidden)
}

// TODO: documentation
pub fn (child &Widget) id() string {
	return child.id
}

// Find if there is recursively a parent deactivated (i.e. z_index <= ui.z_index_hidden)
// used in accordion component
pub fn (w &Widget) has_parent_deactivated() bool {
	p := w.parent
	if p is Stack {
		// println("hpd $w.id: $p.z_index")
		return p.deactivated || p.z_index <= z_index_hidden || Widget(p).has_parent_deactivated()
	} else if p is CanvasLayout {
		// println("hpd $w.id: $p.z_index")
		return p.deactivated || p.z_index <= z_index_hidden || Widget(p).has_parent_deactivated()
	} else if p is Group {
		// println("hpd $w.id: $p.z_index")
		return p.z_index <= z_index_hidden || Widget(p).has_parent_deactivated()
	}
	return false
}

// returns the bounds of a Widget
pub fn (mut w Widget) bounds() gg.Rect {
	sw, sh := w.size()
	return gg.Rect{w.x, w.y, sw, sh}
}

// TODO: documentation
pub fn (mut w Widget) scaled_bounds() gg.Rect {
	sw, sh := w.size()
	sc := gg.dpi_scale()
	return gg.Rect{w.x * sc, w.y * sc, sw * sc, sh * sc}
}

// Is this a Widget from SubWindow? And if yes, return it too as a Layout
pub fn (w Widget) subwindow_parent() (bool, Layout) {
	mut p := w.parent
	for {
		if mut p is Window {
			break
		}
		if mut p is SubWindow {
			return true, p
		}
		if mut p is Widget {
			wp := p as Widget
			p = wp.parent
			continue
		}
		break
	}
	return false, Layout(empty_stack)
}

// used to detect active Stack and CanvasLayout with children (no result of canvas_plus more considered as a real widget)
pub fn (w Widget) is_layout_with_children() bool {
	if w is Layout {
		l := w as Layout
		return l.get_children().len > 0
	} else {
		return false
	}
}

// TODO: documentation
pub fn (w Widget) has_focus() bool {
	if w is Focusable {
		fw := w as Focusable
		return fw.is_focused
	}
	return false
}

// TODO: documentation
pub fn (w Widget) debug_gg_rect(r gg.Rect, color gx.Color) {
	dd := w.ui.dd
	dd.draw_rect_empty(r.x, r.y, r.width, r.height, color)
}

// children contains pure widgets (no stack or group), canvas_layout considered here as a widget (as it is the case ver often for component)
pub fn is_children_have_widget(children []Widget) bool {
	tmp := children.filter(!(it is Stack || it is Group))
	return tmp.len > 0
}

// TODO: documentation
pub fn (w Widget) is_in_parent_tree(parent Widget) bool {
	if parent is Layout {
		if w.parent.id == parent.id {
			return true
		} else {
			// p := w.parent
			// if p is Widget {
			// 	wi := p as Widget

			// }
			return false
		}
	} else {
		return false
	}
}

// TODO: documentation
pub fn (w Widget) window() &Window {
	return w.ui.window
}

// Shorten w.ui.window.get_or_panic
pub fn (w Widget) get[T](id string) &T {
	return w.ui.window.get_or_panic[T](id)
}

//

pub fn (w Widget) is_wm_mode() bool {
	return w.ui.window.is_wm_mode
}

pub fn (w Widget) has_wm_parent_top_subwindow() bool {
	if !w.is_wm_mode() || w.parent is Window {
		return false
	}
	if w.ui.window.subwindows.len > 0 && w.parent.id == w.ui.window.subwindows.last().layout.id {
		return true
	} else {
		mut pw := w.parent.as_widget()
		return pw.has_wm_parent_top_subwindow()
	}
	return false
}
