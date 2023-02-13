module ui

const (
	id_append_top_layer = '___ON_TOP_LAYER___'
)

// CanvasLayout as Layer

// Used to absolute coordinates on top (of everything)
pub fn canvas_layer(c CanvasLayoutParams) &CanvasLayout {
	mut cl := canvas_layout(c)
	cl.is_root_layout = false
	cl.id = 'top_layer'
	cl.z_index = -1
	cl.clipping = false
	cl.active_evt_mngr = false
	cl.is_canvas_layer = true
	cl.update_style_params(bg_color: transparent)
	// println('canvas_layer $cl.id')
	return cl
}

pub fn (mut c CanvasLayout) add_top_layer(w Widget) {
	if c.is_canvas_layer {
		c.children << w
		c.drawing_children << w
	}
}

pub fn (mut window Window) add_top_layer(w Widget) {
	window.top_layer.add_top_layer(w)
}

// init for top layer
fn (mut window Window) init_top_layer() {
	window.top_layer.init(window)
	window.top_layer.width = window.width
	window.top_layer.height = window.height
	window.top_layer.update_layout()
}
