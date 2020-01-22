module ui

struct EventNames{
	on_click string = "on_click"
	on_mouse_move string = "on_mouse_move"
	on_key_down   string = "on_key_down"
}

const (
	events = EventNames{}
)