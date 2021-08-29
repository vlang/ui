module ui

// Managing mouse (down) events for widgets
struct EventMngr {
mut:
	mouse_down_receivers    []Widget
	mouse_down_point_inside []Widget
}

pub fn (mut em EventMngr) add_receiver(widget Widget, evt_types []string) {
	for evt_type in evt_types {
		match evt_type {
			events.on_mouse_down {
				// BUG: 'widget in em.mouse_down_receivers' is failing
				// WORKAROUND with id
				if !(widget.id in em.mouse_down_receivers.map(it.id)) {
					em.mouse_down_receivers << widget
				}
			}
			else {}
		}
	}
}

pub fn (mut em EventMngr) rm_receiver(widget Widget, evt_types []string) {
	for evt_type in evt_types {
		match evt_type {
			events.on_mouse_down {
				// BUG: ind := em.mouse_down_receivers.index(widget)
				// WORKAROUND with id
				ind := em.mouse_down_receivers.map(it.id).index(widget.id)
				if ind >= 0 {
					em.mouse_down_receivers.delete(ind)
				}
			}
			else {}
		}
	}
}

pub fn (mut em EventMngr) point_inside_mouse_down_receivers(e MouseEvent) {
	// TODO first sort mouse_down_receivers by order, z_index and hidden
	em.mouse_down_point_inside.clear()
	for mut w in em.mouse_down_receivers {
		if !w.hidden && w.point_inside(e.x, e.y) {
			em.mouse_down_point_inside << w
		}
	}
}

// pub fn (w Widget)
