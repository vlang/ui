module component

import ui
import gx
import math
import regex
import ui.libvg

type RasterViewFn = fn (rv &RasterViewComponent)

@[heap]
pub struct RasterViewComponent {
pub mut:
	id     string
	layout &ui.CanvasLayout = unsafe { nil }
	r      &libvg.Raster    = unsafe { nil }
	// width      int
	// height     int
	// channels   int = 4
	// data       []u8
	size       int = 11 // pixel_size + inter
	inter      int = 1
	pixel_size int = 10
	// cur_pos
	cur_i int = -1
	cur_j int = -1
	// bounds
	bounds_i int // top
	bounds_j int // left
	bounds_w int // width
	bounds_h int // height
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
	color   gx.Color               = gx.black
	palette &ColorPaletteComponent = unsafe { nil }
	// shortcuts
	key_shortcuts  ui.KeyShortcuts
	char_shortcuts ui.CharShortcuts
	// callback
	on_click RasterViewFn = unsafe { RasterViewFn(0) }
}

@[params]
pub struct RasterViewParams {
pub:
	id       string
	width    int          = 16
	height   int          = 16
	channels int          = 4
	on_click RasterViewFn = unsafe { RasterViewFn(0) }
}

// TODO: documentation
pub fn rasterview_canvaslayout(p RasterViewParams) &ui.CanvasLayout {
	mut layout := ui.canvas_layout(
		id:               ui.component_id(p.id, 'layout')
		scrollview:       true
		justify:          [0.5, 0.5]
		on_draw:          rv_draw
		on_click:         rv_click
		on_mouse_down:    rv_mouse_down
		on_mouse_up:      rv_mouse_up
		on_scroll:        rv_scroll
		on_mouse_move:    rv_mouse_move
		on_mouse_enter:   rv_mouse_enter
		on_mouse_leave:   rv_mouse_leave
		on_key_down:      rv_key_down
		full_size_fn:     rv_full_size
		on_scroll_change: rv_scroll_change
	)
	rv := &RasterViewComponent{
		id:     p.id
		layout: layout
		// width: p.width
		// height: p.height
		// channels: p.channels
		// data: []u8{len: p.width * p.height * p.channels}
		r:        libvg.raster(
			width:    p.width
			height:   p.height
			channels: p.channels
		)
		on_click: p.on_click
	}
	ui.component_connect(rv, layout)
	layout.on_init = rv_init
	return layout
}

// TODO: documentation
pub fn rasterview_component(w ui.ComponentChild) &RasterViewComponent {
	return unsafe { &RasterViewComponent(w.component) }
}

// TODO: documentation
pub fn rasterview_component_from_id(w &ui.Window, id string) &RasterViewComponent {
	return rasterview_component(w.get_or_panic[ui.CanvasLayout](ui.component_id(id, 'layout')))
}

// TODO: documentation
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

fn rv_draw(mut d ui.DrawDevice, c &ui.CanvasLayout) {
	// Calculate the color of each pixel
	mut rv := rasterview_component(c)
	// N.B.: rv.size = rv.pixel_size + rv.inter
	c.draw_device_rect_empty(d, 0, 0, rv.width() * rv.size, rv.height() * rv.size, gx.gray)
	mut pos_x, mut pos_y := rv.from_x, rv.from_y
	mut col := gx.white
	for i in rv.from_i .. rv.to_i {
		for j in rv.from_j .. rv.to_j {
			col = rv.get_pixel(i, j)
			pos_x = j * rv.size
			pos_y = i * rv.size
			c.draw_device_rect_filled(d, pos_x, pos_y, rv.pixel_size, rv.pixel_size, col)
		}
	}
	rv.draw_device_selection(d)
	rv.draw_device_current(d)
}

fn rv_key_down(c &ui.CanvasLayout, e ui.KeyEvent) {
	mut rv := rasterview_component(c)
	mut paint := false
	match e.key {
		.space {
			paint = true
		}
		.up {
			if ui.alt_key(e.mods) {
				// println("move up")
				rv.move_pixels(-1, 0)
			} else {
				if rv.sel_i > 0 {
					rv.sel_i -= 1
					paint = true
				}
			}
		}
		.down {
			if ui.alt_key(e.mods) {
				// println("move down")
				rv.move_pixels(1, 0)
			} else {
				if rv.sel_i < rv.height() - 1 {
					rv.sel_i += 1
					paint = true
				}
			}
		}
		.left {
			if ui.alt_key(e.mods) {
				// println("move left")
				rv.move_pixels(0, -1)
			} else {
				if rv.sel_j > 0 {
					rv.sel_j -= 1
					paint = true
				}
			}
		}
		.right {
			if ui.alt_key(e.mods) {
				// println("move right")
				rv.move_pixels(0, 1)
			} else {
				if rv.sel_j < rv.width() - 1 {
					rv.sel_j += 1
					paint = true
				}
			}
		}
		else {}
	}
	if paint && unsafe { rv.palette != 0 } && ui.shift_key(e.mods) {
		cbc := colorbutton_component_from_id(c.ui.window, rv.palette.selected)
		rv.r.set_pixel(rv.sel_i, rv.sel_j, cbc.bg_color)
	}
}

fn rv_click(c &ui.CanvasLayout, e ui.MouseEvent) {
	mut rv := rasterview_component(c)
	rv.sel_i, rv.sel_j = rv.get_index_pos(e.x, e.y)
	if rv.on_click != unsafe { RasterViewFn(0) } {
		rv.on_click(rv)
	}
}

fn rv_mouse_down(mut c ui.CanvasLayout, e ui.MouseEvent) {
	c.focus()
}

fn rv_mouse_up(c &ui.CanvasLayout, e ui.MouseEvent) {
}

fn rv_scroll(c &ui.CanvasLayout, e ui.ScrollEvent) {
	// TODO: to fix
	mut rv := rasterview_component(c)
	// println("scroll: ${int(e.mouse_x)}, ${int(e.mouse_y)} in $c.x + $c.offset_x + $c.adj_width=${c.x + c.offset_x + c.adj_width},   $c.y + $c.offset_y + $c.adj_height=${c.y + c.offset_y + c.adj_height}")
	if rv.point_inside(int(e.mouse_x), int(e.mouse_y)) {
		rv.cur_i, rv.cur_j = rv.get_index_pos(int(e.mouse_x), int(e.mouse_y))
	} else {
		rv.cur_i, rv.cur_j = -1, -1
	}
}

fn rv_mouse_move(mut c ui.CanvasLayout, e ui.MouseMoveEvent) {
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

fn rv_mouse_enter(mut c ui.CanvasLayout, e ui.MouseMoveEvent) {
	// mut rv := rasterview_component(c)
	// if rv.cur_i != -1 && rv.cur_j != -1 {
	c.ui.window.mouse.start(ui.mouse_hidden)
	// }
}

fn rv_mouse_leave(mut c ui.CanvasLayout, e ui.MouseMoveEvent) {
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

struct Int2 {
	i int
	n int
}

// TODO: documentation
pub fn (rv &RasterViewComponent) top_colors() []gx.Color {
	mut table := map[int]int{}
	mut colors := []gx.Color{}
	mut color, mut ind_color := ui.no_color, 0
	for i in 0 .. rv.height() {
		for j in 0 .. rv.width() {
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

fn (rv &RasterViewComponent) draw_device_current(d ui.DrawDevice) {
	if rv.cur_i < 0 || rv.cur_j < 0 {
		return
	}
	pos_x, pos_y := rv.get_pos(rv.cur_i, rv.cur_j)
	cur_color := gx.cyan
	rv.layout.draw_device_rect_surrounded(d, pos_x, pos_y, rv.pixel_size, rv.pixel_size,
		2, cur_color)
}

fn (rv &RasterViewComponent) draw_device_selection(d ui.DrawDevice) {
	if rv.sel_i < 0 || rv.sel_j < 0 {
		return
	}
	pos_x, pos_y := rv.get_pos(rv.sel_i, rv.sel_j)
	sel_color := gx.red
	rv.layout.draw_device_rect_surrounded(d, pos_x, pos_y, rv.pixel_size, rv.pixel_size,
		3, sel_color)
}

fn (rv &RasterViewComponent) size() (int, int) {
	w := rv.width() * rv.size + rv.inter
	h := rv.height() * rv.size + rv.inter
	return w, h
}

fn (mut rv RasterViewComponent) visible_pixels() {
	if rv.layout.has_scrollview {
		// rv.size := rv.pixel_size + rv.inter
		rv.from_i = math.min(math.max(rv.layout.scrollview.offset_y / rv.size, 0), rv.height() - 1)
		rv.to_i = math.min((rv.layout.scrollview.offset_y +
			rv.layout.height) / rv.size, rv.height() - 1) + 1
		rv.from_y = rv.from_i * rv.size

		rv.from_j = math.min(math.max(rv.layout.scrollview.offset_x / rv.size, 0), rv.width() - 1)
		rv.to_j = math.min((rv.layout.scrollview.offset_x +
			rv.layout.width) / rv.size, rv.width() - 1) + 1
		rv.from_x = rv.from_j * rv.size
	} else {
		rv.from_i, rv.to_i, rv.from_y = 0, rv.height(), 0
		rv.from_j, rv.to_j, rv.from_x = 0, rv.width(), 0
	}
	// println('i: ($rv.from_i, $rv.to_i, $rv.from_y)  j: ($rv.from_j, $rv.to_j, $rv.from_x)')
}

// TODO: documentation
pub fn (mut rv RasterViewComponent) new_image() {
	rv.r.clear()
}

// TODO: documentation
pub fn (mut rv RasterViewComponent) load_image(path string) {
	if mut rv.layout.ui.dd is ui.DrawDeviceContext {
		rv.r.load_image(mut rv.layout.ui.dd.Context, path)
	}
	rv.visible_pixels()
	rv.update_bounds()
	rv.layout.update_layout()
}

// TODO: documentation
pub fn (mut rv RasterViewComponent) save_image_as(path string) {
	rv.r.save_image_as(path)
}

// TODO: documentation
pub fn (mut rv RasterViewComponent) update_bounds() {
	rv.bounds_i, rv.bounds_j, rv.bounds_w, rv.bounds_h = 0, 0, 0, 0
	mut ok := true
	rvw, rvh := rv.width(), rv.height()
	for i in 0 .. rvh {
		for j in 0 .. rvw {
			if rv.get_pixel(i, j) != ui.no_color {
				ok = false
				break
			}
		}
		if ok {
			rv.bounds_i += 1
		} else {
			break
		}
	}
	if rv.bounds_i == rvh - 1 {
		// empty image
		rv.bounds_j = rvw - 1
	} else {
		ok = true
		rv.bounds_h = rvh - rv.bounds_i
		for i := rvh - 1; i > rv.bounds_i; i -= 1 {
			for j in 0 .. rvw {
				if rv.get_pixel(i, j) != ui.no_color {
					ok = false
					break
				}
			}
			if ok {
				rv.bounds_h -= 1
			} else {
				break
			}
		}
	}
	ok = true
	for j in 0 .. rvw {
		for i in rv.bounds_i .. (rv.bounds_i + rv.bounds_h) {
			if rv.get_pixel(i, j) != ui.no_color {
				ok = false
				break
			}
		}
		if ok {
			rv.bounds_j += 1
		} else {
			break
		}
	}
	if rv.bounds_j < rvw - 1 { // otherwise empty image
		ok = true
		rv.bounds_w = rvw - rv.bounds_j
		for j := rvw - 1; j > rv.bounds_j; j -= 1 {
			for i in rv.bounds_i .. (rv.bounds_i + rv.bounds_h) {
				if rv.get_pixel(i, j) != ui.no_color {
					ok = false
					break
				}
			}
			if ok {
				rv.bounds_w -= 1
			} else {
				break
			}
		}
	}
	// println("rv bounds: $rv.bounds_i, $rv.bounds_h, $rv.bounds_j, $rv.bounds_w (${rv.width()}, ${rv.height()})")
}

// TODO: documentation
pub fn (rv &RasterViewComponent) get_margins() (int, int, int, int) { // top, bottom, left, right
	return rv.bounds_i, rv.height() - rv.bounds_i - rv.bounds_h, rv.bounds_j, rv.width() - rv.bounds_j - rv.bounds_w
}

// TODO: documentation
pub fn (mut rv RasterViewComponent) move_pixels(di int, dj int) {
	mt, mb, ml, mr := rv.get_margins()
	if (di == 0 && dj == 0) || (di < 0 && di < -mt) || (di > 0 && di > mb)
		|| (dj < 0 && dj < -ml) || (dj > 0 && dj > mr) {
		return
	}
	mut from_i, mut to_i, mut from_j, mut to_j, mut step_i, mut step_j := (rv.bounds_i + rv.bounds_h - 1), rv.bounds_i, (
		rv.bounds_j + rv.bounds_w - 1), rv.bounds_j, 1, 1

	if di < 0 {
		step_i = -1
		from_i, to_i = to_i, from_i
	}
	if dj < 0 {
		step_j = -1
		from_j, to_j = to_j, from_j
	}

	$if rv_mp ? {
		println('di=${di} for i := ${from_i} * ${step_i}; i >= ${to_i} * ${step_i}; i -= 1')
		println('dj=${dj} for j := ${from_j} * ${step_j}; j >= ${to_j} * ${step_j}; j -= 1')
		if from_i + di >= rv.height() || from_i + di < 0 || to_i + di >= rv.height()
			|| to_i + di < 0 {
			println('erroooorr : ${from_i} + ${di} >= ${rv.height()} || ${from_i} + ${di} < 0 || ${to_i} + ${di} >= ${rv.height()} || ${to_i} + ${di} < 0')
		}
		if from_j + dj >= rv.width() || from_j + dj < 0 || to_j + dj >= rv.width() || to_j + dj < 0 {
			println('erroooorr : ${from_j} + ${dj} >= ${rv.width()} || ${from_j} + ${dj} < 0 || ${to_j} + ${dj} >= ${rv.width()} || ${to_j} + ${dj} < 0')
		}
	}
	for i := from_i * step_i; i >= to_i * step_i; i -= 1 {
		ii := i * step_i
		for j := from_j * step_j; j >= to_j * step_j; j -= 1 {
			jj := j * step_j
			// println("${ii} -> ${ii + di} ($rv.height), ${jj} -> ${jj + dj} (($rv.width))")
			rv.set_pixel(ii + di, jj + dj, rv.get_pixel(ii, jj))
			rv.set_pixel(ii, jj, ui.no_color)
		}
	}
	rv.bounds_i += di
	rv.bounds_j += dj
}

// TODO: documentation
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
		rv.set_raster_size(w, h)
	}
}

// method for raster

// TODO: documentation
pub fn (rv &RasterViewComponent) width() int {
	return rv.r.width
}

// TODO: documentation
pub fn (rv &RasterViewComponent) height() int {
	return rv.r.height
}

// TODO: documentation
pub fn (rv &RasterViewComponent) channels() int {
	return rv.r.channels
}

// TODO: documentation
pub fn (rv &RasterViewComponent) data() &u8 {
	return rv.r.data.data
}

// TODO: documentation
pub fn (mut rv RasterViewComponent) set_raster_size(w int, h int) {
	rv.r.width, rv.r.height = w, h
}

// TODO: documentation
pub fn (rv &RasterViewComponent) get_pixel(i int, j int) gx.Color {
	return rv.r.get_pixel(i, j)
}

// TODO: documentation
pub fn (mut rv RasterViewComponent) set_pixel(i int, j int, col gx.Color) {
	rv.r.set_pixel(i, j, col)
}
