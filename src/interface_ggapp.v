module ui

import gg

interface GGApp {
mut:
	gg &gg.Context
	bounds gg.Rect // bounding box where to draw
	on_init()
	on_draw()
	on_delegate(&gg.Event)
	set_bounds(gg.Rect)
	run()
}
