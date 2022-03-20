module component

import ui
import gx
import gg
import math
import os
import stbi

[heap]
struct RasterViewComponent {
pub mut:
	id       string
	layout   &ui.CanvasLayout
	width    int
	height   int
	channels int = 4
	data     []byte
	size     int = 5
	inter    int = 1
	// from
	from_x int
	from_y int
	from_i int
	to_i   int
	from_j int
	to_j   int
}

[params]
pub struct RasterViewComponentParams {
	id       string
	width    int = 16
	height   int = 16
	channels int = 4
}

pub fn rasterview_canvaslayout(p RasterViewComponentParams) &ui.CanvasLayout {
	mut layout := ui.canvas_layout(
		id: ui.component_part_id(p.id, 'layout')
		scrollview: true
		bg_color: gx.white
		on_draw: rv_draw
		on_click: rv_click
		on_mouse_down: rv_mouse_down
		on_mouse_up: rv_mouse_up
		on_scroll: rv_scroll
		on_mouse_move: rv_mouse_move
		full_size_fn: rv_full_size
		on_scroll_change: rv_scroll_change
	)
	rv := &RasterViewComponent{
		id: p.id
		layout: layout
		width: p.width
		height: p.height
		channels: p.channels
		data: []byte{len: p.width * p.height * p.channels}
	}
	ui.component_connect(rv, layout)
	layout.component_init = rv_init
	return layout
}

pub fn rasterview_component(w ui.ComponentChild) &RasterViewComponent {
	return &RasterViewComponent(w.component)
}

pub fn rasterview_component_from_id(w &ui.Window, id string) &RasterViewComponent {
	return rasterview_component(w.canvas_layout(ui.component_part_id(id, 'layout')))
}

fn rv_init(mut layout ui.CanvasLayout) {
	mut rv := rasterview_component(layout)
	rv.visible_pixels()
	println('init rasterview')
	ui.lock_scrollview_key(layout)
}

fn rv_full_size(mut c ui.CanvasLayout) (int, int) {
	w, h := rasterview_component(c).size()
	c.adj_width, c.adj_height = w, h
	return w, h
}

fn rv_scroll_change(sw ui.ScrollableWidget) {
	if sw is ui.CanvasLayout {
		mut rv := rasterview_component(sw)
		rv.visible_pixels()
	}
}

fn rv_draw(c &ui.CanvasLayout, app voidptr) {
	// Calculate the color of each pixel
	mut rv := rasterview_component(c)
	mut k := 0
	pixel_size := rv.size + rv.inter
	mut pos_x, mut pos_y := rv.from_x, rv.from_y
	mut col := gx.white
	for i in rv.from_i .. rv.to_i {
		for j in rv.from_j .. rv.to_j {
			k = (i * rv.width + j) * rv.channels
			if rv.channels == 4 {
				col = gx.rgba(rv.data[k], rv.data[k + 1], rv.data[k + 2], rv.data[k + 3])
			} else {
				col = gx.rgb(rv.data[k], rv.data[k + 1], rv.data[k + 2])
			}
			pos_x = j * pixel_size
			pos_y = i * pixel_size
			c.draw_rect_filled(pos_x, pos_y, rv.size, rv.size, col)
		}
	}
}

fn rv_click(e ui.MouseEvent, c &ui.CanvasLayout) {
}

fn rv_mouse_down(e ui.MouseEvent, c &ui.CanvasLayout) {}

fn rv_mouse_up(e ui.MouseEvent, c &ui.CanvasLayout) {}

fn rv_scroll(e ui.ScrollEvent, c &ui.CanvasLayout) {
}

fn rv_mouse_move(e ui.MouseMoveEvent, c &ui.CanvasLayout) {
}

fn (rv &RasterViewComponent) size() (int, int) {
	w := rv.width * (rv.size + rv.inter) + rv.inter
	h := rv.height * (rv.size + rv.inter) + rv.inter
	return w, h
}

fn (mut rv RasterViewComponent) visible_pixels() {
	if rv.layout.has_scrollview {
		pixel_size := (rv.size + rv.inter)
		rv.from_i = math.min(math.max(rv.layout.scrollview.offset_y / pixel_size, 0),
			rv.height - 1)
		rv.to_i = math.min((rv.layout.scrollview.offset_y +
			rv.layout.height) / pixel_size, rv.height - 1) + 1
		rv.from_y = rv.from_i * pixel_size

		rv.from_j = math.min(math.max(rv.layout.scrollview.offset_x / pixel_size, 0),
			rv.width - 1)
		rv.to_j = math.min((rv.layout.scrollview.offset_x +
			rv.layout.width) / pixel_size, rv.width - 1) + 1
		rv.from_x = rv.from_j * pixel_size
	} else {
		rv.from_i, rv.to_i, rv.from_y = 0, rv.height, 0
		rv.from_j, rv.to_j, rv.from_x = 0, rv.width, 0
	}
	// println('i: ($rv.from_i, $rv.to_i, $rv.from_y)  j: ($rv.from_j, $rv.to_j, $rv.from_x)')
}

pub fn (mut rv RasterViewComponent) load(path string) {
	if !os.exists(path) {
		return
	}
	img := rv.layout.ui.gg.create_image(path)
	// println("$img.width, $img.height, $img.nr_channels")
	// println("$img.ok, $img.simg_ok")

	rv.width, rv.height, rv.channels = img.width, img.height, img.nr_channels
	rv.data = []byte{len: rv.width * rv.height * rv.channels}
	unsafe { C.memcpy(rv.data.data, img.data, rv.data.len) }
	rv.visible_pixels()
	rv.layout.ui.window.update_layout()
}

// pub fn (mut rv RasterViewComponent) load(path string) {
// 	stbi_write_png(path string, w int, h int, comp int, buf &byte, row_stride_in_bytes int)

// KEEP HERE TO SAVE FILE
//       if (strcmp(filename, "reference.png") == 0) {
//         color = getPixel(i, j, &intersect);
//       } else if (strcmp(filename, "custom.png") == 0) {
//         color = getAntialiasedPixel(i, j, &intersect, 2);
//       } else {
//         color = getAntialiasedPixel(i, j, &intersect, 5); // Really ramp it up
//       }
//   imageData[imagePos++] = color.r;
//   imageData[imagePos++] = color.g;
//   imageData[imagePos++] = color.b;
