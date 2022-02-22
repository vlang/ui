module ui

struct EventNames {
pub:
	on_click        string = 'on_click'
	on_mouse_move   string = 'on_mouse_move'
	on_mouse_down   string = 'on_mouse_down'
	on_mouse_up     string = 'on_mouse_up'
	on_files_droped string = 'on_files_droped'
	on_swipe        string = 'on_swipe'
	on_touch_move   string = 'on_touch_move'
	on_touch_down   string = 'on_touch_down'
	on_touch_up     string = 'on_touch_up'
	on_key_down     string = 'on_key_down'
	on_char         string = 'on_char'
	on_key_up       string = 'on_key_up'
	on_scroll       string = 'on_scroll'
	on_resize       string = 'on_resize'
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
			em.receivers[ui.events.on_mouse_down] << widget
			$if evt_mngr ? {
				println('add receiver $widget.id for $evt_type')
			}
		}
		// sort it
		em.sorted_receivers(evt_type)
	}
}

pub fn (mut em EventMngr) rm_receiver(widget Widget, evt_types []string) {
	for evt_type in evt_types {
		// BUG: ind := em.mouse_down_receivers.index(widget)
		// WORKAROUND with id
		ind := em.receivers[evt_type].map(it.id).index(widget.id)
		if ind >= 0 {
			em.receivers[evt_type].delete(ind)
		}
		// sort it
		em.sorted_receivers(evt_type)
	}
}

pub fn (mut em EventMngr) point_inside_receivers(e MouseEvent, evt_type string) {
	// TODO first sort mouse_down_receivers by order, z_index and hidden
	em.point_inside[evt_type].clear()
	for mut w in em.receivers[evt_type] {
		$if evt_mngr ? {
			println('point_inside_receivers: $w.id !$w.hidden && ${w.point_inside(e.x,
				e.y)} $w.has_parent_deactivated()')
		}
		if !w.hidden && w.point_inside(e.x, e.y) && !w.has_parent_deactivated() {
			em.point_inside[evt_type] << w
		}
	}
	$if evt_mngr ? {
		println('em.point_inside[$evt_type] = ${em.point_inside[evt_type].map(it.id)}')
	}
}

fn (mut em EventMngr) sorted_receivers(evt_type string) {
	mut sw := []SortedWidget{}
	mut sorted := []Widget{}
	$if ser ? {
		println('(Z_INDEX) em.receivers[$evt_type]: ')
		for i, ch in em.receivers[evt_type] {
			id := ch.id()
			print('($i)[$id -> $ch.z_index] ')
		}
		println('\n')
	}
	for i, child in em.receivers[evt_type] {
		sw << SortedWidget{i, child}
	}
	sw.sort_with_compare(compare_sorted_widget)
	for child in sw {
		sorted << child.w
	}
	em.receivers[evt_type] = sorted.reverse()
	$if ser ? {
		println('(SORTED) em.receivers[evt_type]: ')
		for i, ch in em.receivers[evt_type] {
			id := ch.id()
			print('($i)[$id -> $ch.z_index] ')
		}
		println('\n')
	}
}

pub fn (w Window) is_top_widget(widget Widget, evt_type string) bool {
	mut pi := w.evt_mngr.point_inside[evt_type]
	if w.child_window != 0 {
		pi = pi.filter(Layout(w.child_window).has_child_id(it.id))
	}
	$if evt_mngr ? {
		println('is_top_widget $widget.id ? ${pi.len >= 1 && pi.first().id == widget.id}  with pi = ${pi.map(it.id)} (${pi.map(it.z_index)})')
	}
	return pi.len >= 1 && pi.first().id == widget.id
}

pub fn (w Window) point_inside_receivers(evt_type string) []string {
	return w.evt_mngr.point_inside[evt_type].map(it.id)
}
