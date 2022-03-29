module component

import ui
import gx
import gg
import math
import os
import stbi
import regex

type RasterViewFn = fn (rv &RasterViewComponent)

[heap]
struct RasterViewComponent {
pub mut:
	id         string
	layout     &ui.CanvasLayout
	width      int
	height     int
	channels   int = 4
	data       []byte
	size       int = 11 // pixel_size + inter
	inter      int = 1
	pixel_size int = 10
	// cur_pos
	cur_i int = -1
	cur_j int = -1
	// selection
	sel_i int = -1
	sel_j int = -1
	// from
	from_x int
	from_y int
	from_i int
	to_i   int
	from_j int
	to_j   int
	// current color
	color   gx.Color = gx.black
	palette &ColorPaletteComponent = 0
	// shortcuts
	key_shortcuts  ui.KeyShortcuts
	char_shortcuts ui.CharShortcuts
	// callback
	on_click RasterViewFn
}

[params]
pub struct RasterViewParams {
	id       string
	width    int = 16
	height   int = 16
	channels int = 4
	on_click RasterViewFn = RasterViewFn(0)
}

pub fn rasterview_canvaslayout(p RasterViewParams) &ui.CanvasLayout {
	mut layout := ui.canvas_layout(
		id: ui.component_id(p.id, 'layout')
		scrollview: true
		justify: [0.5, 0.5]
		// bg_color: gx.white
		on_draw: rv_draw
		on_click: rv_click
		on_mouse_down: rv_mouse_down
		on_mouse_up: rv_mouse_up
		on_scroll: rv_scroll
		on_mouse_move: rv_mouse_move
		on_mouse_enter: rv_mouse_enter
		on_mouse_leave: rv_mouse_leave
		on_key_down: rv_key_down
		full_size_fn: rv_full_size
		on_scroll_change: rv_scroll_change
	)
	layout.point_inside_visible = true
	rv := &RasterViewComponent{
		id: p.id
		layout: layout
		width: p.width
		height: p.height
		channels: p.channels
		data: []byte{len: p.width * p.height * p.channels}
		on_click: p.on_click
	}
	ui.component_connect(rv, layout)
	layout.on_init = rv_init
	return layout
}

pub fn rasterview_component(w ui.ComponentChild) &RasterViewComponent {
	return &RasterViewComponent(w.component)
}

pub fn rasterview_component_from_id(w &ui.Window, id string) &RasterViewComponent {
	return rasterview_component(w.canvas_layout(ui.component_id(id, 'layout')))
}

pub fn (mut rv RasterViewComponent) connect_palette(pa &ColorPaletteComponent) {
	rv.palette = pa
}

fn rv_init(mut layout ui.CanvasLayout) {
	mut rv := rasterview_component(layout)
	rv.visible_pixels()
	// println('init rasterview')
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
	// N.B.: rv.size = rv.pixel_size + rv.inter
	c.draw_rect_empty(0, 0, rv.width * rv.size, rv.height * rv.size, gx.gray)
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
			pos_x = j * rv.size
			pos_y = i * rv.size
			c.draw_rect_filled(pos_x, pos_y, rv.pixel_size, rv.pixel_size, col)
		}
	}
	rv.draw_selection()
	rv.draw_current()
}

fn rv_key_down(e ui.KeyEvent, c &ui.CanvasLayout) {
	mut rv := rasterview_component(c)
	mut paint := false
	match e.key {
		.space {
			paint = true
		}
		.up {
			if rv.sel_i > 0 {
				rv.sel_i -= 1
				paint = true
			}
		}
		.down {
			if rv.sel_i < rv.height - 1 {
				rv.sel_i += 1
				paint = true
			}
		}
		.left {
			if rv.sel_j > 0 {
				rv.sel_j -= 1
				paint = true
			}
		}
		.right {
			if rv.sel_j < rv.width - 1 {
				rv.sel_j += 1
				paint = true
			}
		}
		else {}
	}
	if paint && rv.palette != 0 && ui.shift_key(e.mods) {
		cbc := colorbutton_component_from_id(c.ui.window, rv.palette.selected)
		rv.set_pixel(rv.sel_i, rv.sel_j, cbc.bg_color)
	}
}

fn rv_click(e ui.MouseEvent, c &ui.CanvasLayout) {
	mut rv := rasterview_component(c)
	rv.sel_i, rv.sel_j = rv.get_index_pos(e.x, e.y)
	if rv.on_click != RasterViewFn(0) {
		rv.on_click(rv)
	}
}

fn rv_mouse_down(e ui.MouseEvent, mut c ui.CanvasLayout) {
	c.focus()
}

fn rv_mouse_up(e ui.MouseEvent, c &ui.CanvasLayout) {
}

fn rv_scroll(e ui.ScrollEvent, c &ui.CanvasLayout) {
	// TODO: to fix
	mut rv := rasterview_component(c)
	// println("scroll: ${int(e.mouse_x)}, ${int(e.mouse_y)} in $c.x + $c.offset_x + $c.adj_width=${c.x + c.offset_x + c.adj_width},   $c.y + $c.offset_y + $c.adj_height=${c.y + c.offset_y + c.adj_height}")
	if rv.point_inside(int(e.mouse_x), int(e.mouse_y)) {
		rv.cur_i, rv.cur_j = rv.get_index_pos(int(e.mouse_x), int(e.mouse_y))
	} else {
		rv.cur_i, rv.cur_j = -1, -1
	}
}

fn rv_mouse_move(e ui.MouseMoveEvent, mut c ui.CanvasLayout) {
	mut rv := rasterview_component(c)
	// println("move $c.id: ${int(e.x)}, ${int(e.y)} in $c.x + $c.offset_x + $c.adj_width=${c.x + c.offset_x + c.adj_width},   $c.y + $c.offset_y + $c.adj_height=${c.y + c.offset_y + c.adj_height}")
	if rv.point_inside(int(e.x), int(e.y)) {
		rv.cur_i, rv.cur_j = rv.get_index_pos(int(e.x), int(e.y))
		if ui.shift_key(c.ui.keymods) {
			rv.set_pixel(rv.cur_i, rv.cur_j, rv.color)
		}
	} else {
		rv.cur_i, rv.cur_j = -1, -1
	}
}

fn rv_mouse_enter(e ui.MouseMoveEvent, mut c ui.CanvasLayout) {
	// mut rv := rasterview_component(c)
	// if rv.cur_i != -1 && rv.cur_j != -1 {
	c.ui.window.mouse.start(ui.mouse_hidden)
	// }
}

fn rv_mouse_leave(e ui.MouseMoveEvent, mut c ui.CanvasLayout) {
	// mut rv := rasterview_component(c)
	// if rv.cur_i != -1 || rv.cur_j != -1 {
	c.ui.window.mouse.stop_last(ui.mouse_hidden)
	// }
}

fn (rv &RasterViewComponent) point_inside(x int, y int) bool {
	w, h := rv.size()
	return x >= 0 && x <= w && y >= 0 && y <= h
}

fn (rv &RasterViewComponent) get_index_pos(x int, y int) (int, int) {
	mut sel_i, mut sel_j := -1, -1

	mut cum := rv.from_x
	for j in rv.from_j .. rv.to_j {
		cum += rv.size
		if x > rv.from_x && x < cum {
			sel_j = j
			break
		}
	}

	cum = rv.from_y
	for i in rv.from_i .. rv.to_i {
		cum += rv.size
		if y > rv.from_y && y < cum {
			sel_i = i
			break
		}
	}

	return sel_i, sel_j
}

pub fn (rv &RasterViewComponent) get_pixel(i int, j int) gx.Color {
	k := (i * rv.width + j) * rv.channels
	if rv.channels == 4 {
		return gx.rgba(rv.data[k], rv.data[k + 1], rv.data[k + 2], rv.data[k + 3])
	} else if rv.channels == 3 {
		return gx.rgb(rv.data[k], rv.data[k + 1], rv.data[k + 2])
	}
	return ui.no_color
}

pub fn (mut rv RasterViewComponent) set_pixel(i int, j int, color gx.Color) {
	k := (i * rv.width + j) * rv.channels
	if rv.channels == 4 {
		rv.data[k], rv.data[k + 1], rv.data[k + 2], rv.data[k + 3] = color.r, color.g, color.b, color.a
	} else if rv.channels == 3 {
		rv.data[k], rv.data[k + 1], rv.data[k + 2] = color.r, color.g, color.b
	}
}

struct Int2 {
	i int
	n int
}

pub fn (rv &RasterViewComponent) top_colors() []gx.Color {
	mut table := map[int]int{}
	mut colors := []gx.Color{}
	mut color, mut ind_color := ui.no_color, 0
	for i in 0 .. rv.height {
		for j in 0 .. rv.width {
			color = rv.get_pixel(i, j)
			ind_color = colors.index(color)
			if ind_color == -1 {
				colors << color
				ind_color = colors.len - 1
				table[ind_color] = 0
			}
			table[ind_color] += 1
		}
	}
	// sort
	mut table_sorted := []Int2{}
	for k, v in table {
		table_sorted << Int2{k, v}
	}
	table_sorted.sort_with_compare(fn (a &Int2, b &Int2) int {
		if a.n > b.n {
			return -1
		} else if a.n < b.n {
			return 1
		} else {
			return 0
		}
	})
	mut table_color := []gx.Color{}
	for a in table_sorted {
		table_color << colors[a.i]
	}

	return table_color
}

fn (rv &RasterViewComponent) get_pos(i int, j int) (int, int) {
	return j * rv.size, i * rv.size
}

fn (rv &RasterViewComponent) draw_current() {
	if rv.cur_i < 0 || rv.cur_j < 0 {
		return
	}
	pos_x, pos_y := rv.get_pos(rv.cur_i, rv.cur_j)
	cur_color := gx.yellow
	rv.layout.draw_rect_surrounded(pos_x, pos_y, rv.pixel_size, rv.pixel_size, 2, cur_color)
}

fn (rv &RasterViewComponent) draw_selection() {
	if rv.sel_i < 0 || rv.sel_j < 0 {
		return
	}
	pos_x, pos_y := rv.get_pos(rv.sel_i, rv.sel_j)
	sel_color := gx.red
	rv.layout.draw_rect_surrounded(pos_x, pos_y, rv.pixel_size, rv.pixel_size, 3, sel_color)
}

fn (rv &RasterViewComponent) size() (int, int) {
	w := rv.width * rv.size + rv.inter
	h := rv.height * rv.size + rv.inter
	return w, h
}

fn (mut rv RasterViewComponent) visible_pixels() {
	if rv.layout.has_scrollview {
		// rv.size := rv.pixel_size + rv.inter
		rv.from_i = math.min(math.max(rv.layout.scrollview.offset_y / rv.size, 0), rv.height - 1)
		rv.to_i = math.min((rv.layout.scrollview.offset_y +
			rv.layout.height) / rv.size, rv.height - 1) + 1
		rv.from_y = rv.from_i * rv.size

		rv.from_j = math.min(math.max(rv.layout.scrollview.offset_x / rv.size, 0), rv.width - 1)
		rv.to_j = math.min((rv.layout.scrollview.offset_x +
			rv.layout.width) / rv.size, rv.width - 1) + 1
		rv.from_x = rv.from_j * rv.size
	} else {
		rv.from_i, rv.to_i, rv.from_y = 0, rv.height, 0
		rv.from_j, rv.to_j, rv.from_x = 0, rv.width, 0
	}
	// println('i: ($rv.from_i, $rv.to_i, $rv.from_y)  j: ($rv.from_j, $rv.to_j, $rv.from_x)')
}

pub fn (mut rv RasterViewComponent) new_image() {
	rv.channels = 4
	rv.data = []byte{len: rv.width * rv.height * rv.channels}
}

pub fn (mut rv RasterViewComponent) load_image(path string) {
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
	rv.layout.update_layout()
}

pub fn (mut rv RasterViewComponent) save_image_as(path string) {
	stbi.stbi_write_png(path, rv.width, rv.height, rv.channels, rv.data.data, rv.width * rv.channels) or {
		panic(err)
	}
}

pub fn (mut rv RasterViewComponent) extract_size(pngfile string) {
	query := r'.*\-(?P<width>\d+)x?(?P<height>\d+)?\.png'
	mut re := regex.regex_opt(query) or { panic(err) }
	re.match_string(pngfile)
	w := re.get_group_by_name(pngfile, 'width').int()
	if w > 0 {
		mut h := re.get_group_by_name(pngfile, 'height').int()
		if h == 0 {
			h = w
		}
		rv.width, rv.height = w, h
	}
}
