module ui

pub interface EnterLeaveWidget {
mut:
	id string
	mouse_enter(e &MouseMoveEvent)
	mouse_leave(e &MouseMoveEvent)
}
