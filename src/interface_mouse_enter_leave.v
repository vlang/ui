module ui

interface EnterLeaveWidget {
mut:
	id string
	do_mouse_enter(e &MouseMoveEvent)
	do_mouse_leave(e &MouseMoveEvent)
}
