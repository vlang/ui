module ui

interface EnterLeaveWidget {
mut:
	id string
	on_mouse_enter(e &MouseMoveEvent)
	on_mouse_leave(e &MouseMoveEvent)
}
