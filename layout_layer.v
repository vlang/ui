module ui

const (
	id_append_top_layer = '___ON_TOP_LAYER___'
)

// CanvasLayout as Layer

// Used to absolute coordinates on top (of everything)
pub fn canvas_layer(c CanvasLayoutParams) &CanvasLayout {
	mut cl := canvas_layout(c)
	cl.is_canvas_layer = true
	cl.update_style_forced(bg_color: transparent)
	return cl
}

fn (mut c CanvasLayout) init_layer() {
	if c.is_canvas_layer {
		c.width = c.ui.window.width
		c.height = c.ui.window.height
	}
}

pub fn (mut c CanvasLayout) layer_add(w Widget) {
	if c.is_canvas_layer {
		c.children << w
	}
}

// Preprocess for Window for
