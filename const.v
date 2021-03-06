module ui

struct EventNames {
pub:
	on_click      string = 'on_click'
	on_mouse_move string = 'on_mouse_move'
	on_mouse_down string = 'on_mouse_down'
	on_mouse_up   string = 'on_mouse_up'
	on_touch_move string = 'on_touch_move'
	on_touch_down string = 'on_touch_down'
	on_touch_up   string = 'on_touch_up'
	on_key_down   string = 'on_key_down'
	on_char       string = 'on_char'
	on_key_up     string = 'on_key_up'
	on_scroll     string = 'on_scroll'
	on_resize     string = 'on_resize'
}

pub const (
	events = EventNames{}
)
