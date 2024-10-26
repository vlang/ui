module ui

import gg

struct EventNames {
pub:
	on_click         string = 'on_click'
	on_mouse_move    string = 'on_mouse_move'
	on_mouse_down    string = 'on_mouse_down'
	on_mouse_up      string = 'on_mouse_up'
	on_files_dropped string = 'on_files_dropped'
	on_swipe         string = 'on_swipe'
	on_touch_move    string = 'on_touch_move'
	on_touch_down    string = 'on_touch_down'
	on_touch_up      string = 'on_touch_up'
	on_key_down      string = 'on_key_down'
	on_char          string = 'on_char'
	on_key_up        string = 'on_key_up'
	on_scroll        string = 'on_scroll'
	on_resize        string = 'on_resize'
	// on_mouse_enter  string = 'on_mouse_enter'
	// on_mouse_leave  string = 'on_mouse_leave'
	on_delegate string = 'on_delegate'
}

pub const events = EventNames{}

// Managing mouse (down) events for widgets
struct EventMngr {
mut:
	receivers    map[string][]Widget
	point_inside map[string][]Widget
}

pub fn (mut em EventMngr) add_receiver(widget Widget, evt_types []string) {
	for evt_type in evt_types {
		// BUG: 'widget in em.receivers[events.on_mouse_down]' is failing
		// WORKAROUND with id
		if widget.id !in em.receivers[evt_type].map(it.id) {
			em.receivers[evt_type] << widget
			$if em_add ? {
				println('add receiver ${widget.id} (${widget.type_name()}) for ${evt_type}')
				em.list_receivers(evt_type)
			}
		}
		// sort it
		em.sorted_receivers(evt_type)
	}
}

pub fn (mut em EventMngr) rm_receiver(widget Widget, evt_types []string) {
	for evt_type in evt_types {
		$if em_rc ? {
			println('rm_receivers from ${evt_type} widget ${widget.id}')
		}
		// BUG: ind := em.mouse_down_receivers.index(widget)
		// WORKAROUND with id
		ind := em.receivers[evt_type].map(it.id).index(widget.id)
		if ind >= 0 {
			em.receivers[evt_type].delete(ind)
		}
		// sort it
		// bug if uncommented: em.sorted_receivers(evt_type)
	}
}

pub fn (mut em EventMngr) point_inside_receivers_mouse_event(e MouseEvent, evt_type string) {
	// TODO first sort mouse_down_receivers by order, z_index and hidden
	em.point_inside[evt_type].clear()
	em.sorted_receivers(evt_type)
	$if em_mouse ? {
		println('point_inside_receivers_mouse_event em.receivers[${evt_type}]: ')
		em.list_receivers(evt_type)
	}
	for mut w in em.receivers[evt_type] {
		$if em_mouse ? {
			println('point_inside_receivers: ${w.id} [${w.is_visible() && w.is_parent_visible(true)
				&& w.point_inside(e.x, e.y) && !w.has_parent_deactivated()}] (vis: ${w.is_visible()}) && (parentvis: ${w.is_parent_visible(true)}) && (inside: ${w.point_inside(e.x,
				e.y)}) && (!parent deactivated : ${!w.has_parent_deactivated()})')
		}
		if w.is_wm_mode() && !w.has_wm_parent_top_subwindow() {
			continue
		}
		if w.is_visible() && w.is_parent_visible(true) && w.point_inside(e.x, e.y)
			&& !w.has_parent_deactivated() {
			em.point_inside[evt_type] << w
		}
	}
	$if em_mouse ? {
		println('em.point_inside[${evt_type}] = ${em.point_inside[evt_type].map(it.id)}')
	}
}

pub fn (mut em EventMngr) point_inside_receivers_scroll_event(e ScrollEvent) {
	// TODO first sort scroll_receivers by order, z_index and hidden
	evt_type := events.on_scroll
	em.point_inside[evt_type].clear()
	em.sorted_receivers(evt_type)
	$if em_scroll ? {
		println('em.receivers[on_scroll] = ${em.receivers[evt_type].map(it.id)}')
	}
	for mut w in em.receivers[evt_type] {
		$if em_scroll ? {
			println('point_inside_receivers: ${w.id} ${w.is_visible()} && (${e.mouse_x}, ${e.mouse_y}) ${w.point_inside(e.mouse_x,
				e.mouse_y)} ${w.has_parent_deactivated()}')
		}
		if w is ScrollableWidget {
			sw := w as ScrollableWidget
			if w.is_visible() && has_scrollview(sw)
				&& sw.scrollview.point_inside(e.mouse_x, e.mouse_y, .view)
				&& !has_child_with_active_scrollview(w, e.mouse_x, e.mouse_y)
				&& !w.has_parent_deactivated() {
				em.point_inside[evt_type] << w
			}
		} else {
			if w.is_visible() && w.is_parent_visible(true) && w.point_inside(e.mouse_x, e.mouse_y)
				&& !w.has_parent_deactivated() {
				em.point_inside[evt_type] << w
			}
		}
	}
	$if em_scroll ? {
		println('em.point_inside[${evt_type}] = ${em.point_inside[evt_type].map(it.id)} , ${em.point_inside[evt_type].map(it.z_index)}')
	}
}

pub fn (mut em EventMngr) point_inside_receivers_mouse_move(e MouseMoveEvent) {
	// TODO first sort scroll_receivers by order, z_index and hidden
	evt_type := events.on_mouse_move
	point_inside_ids := em.point_inside[evt_type].map(it.id)
	em.point_inside[evt_type].clear()
	em.sorted_receivers(evt_type)
	$if em_mouse_move ? {
		println('em.receivers[on_mouse_move] = ${em.receivers[evt_type].map(it.id)}')
	}
	for mut w in em.receivers[evt_type] {
		$if em_mouse_move ? {
			println('point_inside_receivers: ${w.id} ${w.is_visible()} && (${e.x}, ${e.y}) ${w.point_inside(int(e.x),
				int(e.y))} ${w.has_parent_deactivated()}')
		}
		if w.is_visible() && w.is_parent_visible(true) && w.point_inside(int(e.x), int(e.y))
			&& !w.has_parent_deactivated() {
			if w.id !in point_inside_ids {
				if mut w is EnterLeaveWidget {
					mut elw := w as EnterLeaveWidget
					elw.mouse_enter(e)
				}
			}
			em.point_inside[evt_type] << w
		} else {
			if w.id in point_inside_ids {
				if mut w is EnterLeaveWidget {
					mut elw := w as EnterLeaveWidget
					elw.mouse_leave(e)
				}
			}
		}
	}
	$if em_mouse_move ? {
		println('em.point_inside[${evt_type}] = ${em.point_inside[evt_type].map(it.id)} , ${em.point_inside[evt_type].map(it.z_index)}')
	}
}

pub fn (mut em EventMngr) sorted_receivers(evt_type string) {
	mut sw := []SortedWidget{}
	mut sorted := []Widget{}
	$if em_sr ? {
		println('Before sort: (${evt_type})')
		em.list_receivers(evt_type)
	}
	for i, child in em.receivers[evt_type] {
		sw << SortedWidget{i, child}
	}
	sw.sort_with_compare(compare_sorted_widget)
	for child in sw {
		sorted << child.w
	}
	em.receivers[evt_type] = sorted.reverse()
	$if em_sr ? {
		println('(SORTED) em.receivers[${evt_type}]: ')
		em.list_receivers(evt_type)
	}
}

pub fn (w Window) is_top_widget(widget Widget, evt_type string) bool {
	mut pi := w.evt_mngr.point_inside[evt_type]
	if unsafe { w.child_window != 0 } {
		pi = pi.filter(Layout(w.child_window).has_child_id(it.id))
	}
	$if em_itw ? {
		println('is_top_widget (${evt_type}) ${widget.id} ? ${pi.len >= 1
			&& pi.first().id == widget.id}  with pi = ${pi.map(it.id)} (${pi.map(it.z_index)})')
	}
	return pi.len >= 1 && pi.first().id == widget.id
}

pub fn (w Window) point_inside_receivers(evt_type string) []string {
	return w.evt_mngr.point_inside[evt_type].map(it.id)
}

// used for debug
pub fn (em &EventMngr) list_receivers(evt_type string) {
	print('receivers list for ${evt_type} (${em.receivers[evt_type].len}): ')
	for i, ch in em.receivers[evt_type] {
		id := ch.id()
		print('(${i})[${id}: ${ch.z_index}] ')
	}
	println('\n')
}

// delegation (useful for iui interconnection)

fn (em &EventMngr) has_delegation(e &gg.Event, gui &UI) bool {
	if em.receivers[events.on_delegate].len > 0 {
		for mut w in em.receivers[events.on_delegate] {
			x, y := e.mouse_x / gui.window.dpi_scale, e.mouse_y / gui.window.dpi_scale
			if w.point_inside(x, y) {
				return true
			}
		}
		return false
	} else {
		return false
	}
}
