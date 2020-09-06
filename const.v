module ui

struct EventNames {
pub:
	on_click      string = 'on_click'
	on_mouse_move string = 'on_mouse_move'
	on_mouse_down string = 'on_mouse_down'
	on_mouse_up   string = 'on_mouse_up'
	on_key_down   string = 'on_key_down'
	on_key_up     string = 'on_key_up'
	on_scroll     string = 'on_scroll'
}

pub const (
	events = EventNames{}
)
