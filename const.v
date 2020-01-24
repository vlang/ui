module ui

struct EventNames{
	on_click string = "on_click"
	on_mouse_move string = "on_mouse_move"
	on_key_down   string = "on_key_down"
	on_key_up	  string = "on_key_up"
}

const (
	events = EventNames{}
)