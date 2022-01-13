module component

import ui
import gx

pub const cb_sp = 3

pub const cb_hsv_col = 30

pub const cb_nc = 2

pub const cb_nr = 3

pub const cb_cv_hsv_w = (cb_hsv_col + cb_sp) * cb_nc + cb_sp

pub const cb_cv_hsv_h = (cb_hsv_col + cb_sp) * cb_nr + cb_sp

type RgbToHsv = fn (col gx.Color) (f64, f64, f64)

type HsvToRgb = fn (f64, f64, f64) gx.Color

struct HSVColor {
	h f64
	s f64
	v f64
}

[heap]
struct ColorBox {
mut:
	simg       C.sg_image
	h          f64 = 0.0
	s          f64 = 0.75
	v          f64 = 0.75
	rgb        gx.Color
	linked     &gx.Color = &gx.Color(0)
	ind_sel    int
	hsv_sel    []HSVColor = []HSVColor{len: component.cb_nc * component.cb_nr}
	txt_r      string
	txt_g      string
	txt_b      string
	rgb_to_hsv RgbToHsv = ui.rgb_to_hsv
	hsv_to_rgb HsvToRgb = ui.hsv_to_rgb
	// options
	light bool // light theme
	hsl   bool // use hsl instead of hsv
	drag  bool // drag mode for canvas on h
pub mut:
	layout     &ui.Stack // required
	cv_h       &ui.CanvasLayout
	cv_sv      &ui.CanvasLayout
	r_rgb_cur  &ui.Rectangle
	cv_hsv_sel &ui.CanvasLayout
	tb_r       &ui.TextBox
	tb_g       &ui.TextBox
	tb_b       &ui.TextBox
	lb_r       &ui.Label
	lb_g       &ui.Label
	lb_b       &ui.Label
	// To become a component of a parent component
	component voidptr
}

[params]
pub struct ColorBoxConfig {
	id    string
	light bool
	hsl   bool
	drag  bool
}

pub fn colorbox(c ColorBoxConfig) &ui.Stack {
	mut cv_h := ui.canvas_plus(
		width: 30
		height: 256
		on_draw: cv_h_draw
		on_click: cv_h_click
		// on_mouse_move: cv_h_mouse_move
	)
	mut cv_sv := ui.canvas_plus(
		width: 256
		height: 256
		on_draw: cv_sv_draw
		on_mouse_move: cv_sv_mouse_move
		on_click: cv_sv_click
	)
	mut r_rgb_cur := ui.rectangle(
		radius: 5
	)
	mut cv_hsv_sel := ui.canvas_plus(
		bg_radius: 5
		bg_color: gx.rgb(220, 220, 220)
		on_draw: cv_sel_draw
		on_click: cv_sel_click
		on_key_down: cv_sel_key_down
	)
	mut tb_r := ui.textbox(is_numeric: true, on_char: tb_char)
	mut tb_g := ui.textbox(is_numeric: true, on_char: tb_char)
	mut tb_b := ui.textbox(is_numeric: true, on_char: tb_char)
	lb_r := ui.label(text: 'R:')
	lb_g := ui.label(text: 'G:')
	lb_b := ui.label(text: 'B:')
	mut layout := ui.row(
		id: c.id
		width: 30 + 256 + 4 * 10 + component.cb_cv_hsv_w
		height: 256 + 2 * 10
		widths: [30.0, 256.0, ui.compact]
		heights: [256.0, 256.0, ui.compact]
		spacing: 10.0
		margin_: 10
		children: [
			cv_h,
			cv_sv,
			ui.column(
				heights: [f64(component.cb_cv_hsv_h), component.cb_cv_hsv_w, ui.compact, ui.compact,
					ui.compact]
				widths: f64(component.cb_cv_hsv_w)
				spacing: 5.0
				children: [cv_hsv_sel, r_rgb_cur,
					ui.row(
					widths: [20.0, ui.stretch]
					children: [lb_r, tb_r]
				),
					ui.row(
						widths: [20.0, ui.stretch]
						children: [lb_g, tb_g]
					),
					ui.row(
						widths: [20.0, ui.stretch]
						children: [lb_b, tb_b]
					)]
			),
		]
	)
	mut cb := &ColorBox{
		layout: layout
		cv_h: cv_h
		cv_sv: cv_sv
		r_rgb_cur: r_rgb_cur
		cv_hsv_sel: cv_hsv_sel
		tb_r: tb_r
		tb_g: tb_g
		tb_b: tb_b
		lb_r: lb_r
		lb_g: lb_g
		lb_b: lb_b
		light: c.light
		hsl: c.hsl
		drag: c.drag
	}

	ui.component_connect(cb, layout, cv_h, cv_sv, r_rgb_cur, cv_hsv_sel, tb_r, tb_g, tb_b)

	tb_r.text = &cb.txt_r
	tb_g.text = &cb.txt_g
	tb_b.text = &cb.txt_b
	// init component
	layout.component_init = colorbox_init
	return layout
}

// component access
pub fn component_colorbox(w ui.ComponentChild) &ColorBox {
	return &ColorBox(w.component)
}

// equivalent of init method for widget
// automatically called in by the layout
fn colorbox_init(layout &ui.Stack) {
	mut cb := component_colorbox(layout)
	cb.update_hsl()
	cb.update_cur_color(true)
	// init all hsv colors
	for i in 0 .. (component.cb_nc * component.cb_nr) {
		cb.hsv_sel[i] = HSVColor{f64(i) / (component.cb_nc * component.cb_nr), .75, .75}
	}
	cb.update_theme()
	cb.simg = ui.create_dynamic_texture(256, 256)
	cb.update_buffer()
}

pub fn (mut cb ColorBox) connect(col &gx.Color) {
	cb.linked = unsafe { col }
}

fn cv_h_click(e ui.MouseEvent, c &ui.CanvasLayout) {
	mut cb := component_colorbox(c)
	cb.h = f64(e.y) / 256
	cb.update_buffer()
}

fn cv_h_mouse_move(e ui.MouseMoveEvent, c &ui.CanvasLayout) {
	if c.ui.btn_down[0] {
		mut cb := component_colorbox(c)
		cb.h = f64(e.y) / 256
		cb.update_buffer()
	}
}

fn cv_h_draw(c &ui.CanvasLayout, app voidptr) {
	cb := component_colorbox(c)
	for j in 0 .. 255 {
		c.draw_rect(0, j, 30, 1, cb.hsv_to_rgb(f64(j) / 256.0, .75, .75))
	}
	c.draw_rounded_rect(-3, int(cb.h * 256) - 3, 36, 6, 2, cb.hsv_to_rgb(cb.h, .2, .7))
	c.draw_rect(3, int(cb.h * 256) - 1, 24, 2, cb.hsv_to_rgb(cb.h, .75, .75))
	c.draw_empty_rounded_rect(-3, int(cb.h * 256) - 3, 36, 6, 2, if cb.light {
		gx.black
	} else {
		gx.white
	})
}

fn cv_sv_click(e ui.MouseEvent, c &ui.CanvasLayout) {
	mut cb := component_colorbox(c)
	cb.s = f64(e.x) / 255.0
	cb.v = 1.0 - f64(e.y) / 255.0
	cb.update_cur_color(true)
	cb.update_sel_color()
}

fn cv_sv_mouse_move(e ui.MouseMoveEvent, c &ui.CanvasLayout) {
	if c.ui.btn_down[0] {
		mut cb := component_colorbox(c)
		cb.s = f64(e.x) / 255.0
		cb.v = 1.0 - f64(e.y) / 255.0
		cb.update_cur_color(true)
	}
}

fn cv_sv_draw(mut c ui.CanvasLayout, app voidptr) {
	mut cb := component_colorbox(c)

	c.draw_texture(cb.simg)

	c.draw_rounded_rect(int(cb.s * 256.0) - 10, int((1.0 - cb.v) * 256.0) - 10, 20, 20,
		10, cb.hsv_to_rgb(cb.h, 1 - cb.s, 1.0 - cb.v))
	c.draw_rounded_rect(int(cb.s * 256.0) - 7, int((1.0 - cb.v) * 256.0) - 7, 14, 14,
		7, cb.hsv_to_rgb(cb.h, cb.s, cb.v))
}

fn cv_sel_key_down(e ui.KeyEvent, c &ui.CanvasLayout) {
	mut cb := component_colorbox(c)
	if e.key in [.up, .down] {
		cb.hsl = !cb.hsl
		cb.update_hsl()
		cb.update_buffer()
		cb.update_from_tb()
		cb.update_cur_color(true)
	} else if e.key == .right {
		cb.light = !cb.light
		cb.update_theme()
	} else if e.key == .left {
		cb.drag = !cb.drag
		cb.update_drag_mode()
	}
}

fn cv_sel_click(e ui.MouseEvent, c &ui.CanvasLayout) {
	mut cb := component_colorbox(c)
	i := (e.x - component.cb_sp) / (component.cb_sp + component.cb_hsv_col)
	j := (e.y - component.cb_sp) / (component.cb_sp + component.cb_hsv_col)
	cb.ind_sel = i + j * component.cb_nc
	// println("($i, $j) -> ${cb.ind_sel}")
	hsv := cb.hsv_sel[cb.ind_sel]
	cb.h, cb.s, cb.v = hsv.h, hsv.s, hsv.v
	cb.update_buffer()
	cb.update_cur_color(true)
}

fn cv_sel_draw(mut c ui.CanvasLayout, app voidptr) {
	cb := component_colorbox(c)
	mut hsv := HSVColor{}
	mut h, mut s, mut v := 0.0, 0.0, 0.0
	ii, jj := cb.ind_sel % component.cb_nc, cb.ind_sel / component.cb_nc
	c.draw_rounded_rect(component.cb_sp + ii * (component.cb_hsv_col + component.cb_sp) - 1,
		component.cb_sp + jj * (component.cb_hsv_col + component.cb_sp) - 1, component.cb_hsv_col +
		2, component.cb_hsv_col + 2, .25, gx.black)
	for j in 0 .. component.cb_nr {
		for i in 0 .. component.cb_nc {
			hsv = cb.hsv_sel[i + j * component.cb_nc]
			h, s, v = hsv.h, hsv.s, hsv.v
			c.draw_rounded_rect(component.cb_sp + i * (component.cb_hsv_col + component.cb_sp),
				component.cb_sp + j * (component.cb_hsv_col + component.cb_sp), component.cb_hsv_col,
				component.cb_hsv_col, .25, cb.hsv_to_rgb(h, s, v))
		}
	}
}

pub fn (mut cb ColorBox) update_cur_color(reactive bool) {
	cb.r_rgb_cur.color = cb.hsv_to_rgb(cb.h, cb.s, cb.v)
	if cb.linked != 0 {
		unsafe {
			*cb.linked = cb.r_rgb_cur.color
		}
	}
	if reactive {
		cb.txt_r = cb.r_rgb_cur.color.r.str()
		cb.txt_g = cb.r_rgb_cur.color.g.str()
		cb.txt_b = cb.r_rgb_cur.color.b.str()
	}
}

pub fn (mut cb ColorBox) update_sel_color() {
	// cb.r_sel.color = cb.hsv_to_rgb(cb.h, cb.s, cb.v)
	cb.hsv_sel[cb.ind_sel] = HSVColor{cb.h, cb.s, cb.v}
}

pub fn (mut cb ColorBox) update_buffer() {
	unsafe { ui.destroy_texture(cb.simg) }
	sz := 256 * 256 * 4
	buf := unsafe { malloc(sz) }
	mut col := gx.Color{}
	mut i := 0
	for y in 0 .. 256 {
		for x in 0 .. 256 {
			unsafe {
				col = cb.hsv_to_rgb(cb.h, f64(x) / 255.0, 1.0 - f64(y) / 255.0)
				buf[i] = col.r
				buf[i + 1] = col.g
				buf[i + 2] = col.b
				buf[i + 3] = col.a
				i += 4
			}
		}
	}
	unsafe {
		cb.simg = ui.create_texture(256, 256, buf)
		// update_text_texture(cb.simg, 256, 256, buf)
		free(buf)
	}
}

fn tb_char(a voidptr, tb &ui.TextBox, cp u32) {
	mut cb := component_colorbox(tb)
	r, g, b := cb.txt_r.int(), cb.txt_g.int(), cb.txt_b.int()
	cb.update_from_rgb(r, g, b)
}

pub fn (mut cb ColorBox) update_from_rgb(r int, g int, b int) {
	if 0 <= r && r < 256 {
		if 0 <= g && g < 256 {
			if 0 <= b && b < 256 {
				col := gx.rgb(byte(r), byte(g), byte(b))
				// println("ggggg $r, $g, $b ${col}")
				h, s, v := cb.rgb_to_hsv(col)
				// println("hsv: $r, $g, $b ->  $h, $s, $v")
				cb.h, cb.s, cb.v = h, s, v
				cb.update_buffer()
				cb.update_cur_color(false)
				// cb.update_sel_color()
			}
		}
	}
}

fn (mut cb ColorBox) update_from_tb() {
	r := cb.txt_r.int()
	g := cb.txt_g.int()
	b := cb.txt_b.int()
	cb.h, cb.s, cb.v = cb.rgb_to_hsv(gx.rgb(byte(r), byte(g), byte(b)))
}

// options

pub fn (mut cb ColorBox) update_theme() {
	cb.layout.bg_color = if cb.light { gx.rgba(255, 255, 255, 200) } else { gx.rgba(0, 0, 0, 200) }
	lbl_cfg := gx.TextCfg{
		color: if cb.light { gx.black } else { gx.white }
	}
	cb.lb_r.text_cfg = lbl_cfg
	cb.lb_g.text_cfg = lbl_cfg
	cb.lb_b.text_cfg = lbl_cfg
}

pub fn (mut cb ColorBox) update_hsl() {
	if cb.hsl {
		cb.rgb_to_hsv = ui.rgb_to_hsl
		cb.hsv_to_rgb = ui.hsl_to_rgb
	} else {
		cb.rgb_to_hsv = ui.rgb_to_hsv
		cb.hsv_to_rgb = ui.hsv_to_rgb
	}
}

pub fn (mut cb ColorBox) update_drag_mode() {
	if cb.drag {
		cb.cv_h.mouse_move_fn = cv_h_mouse_move
	} else {
		cb.cv_h.mouse_move_fn = voidptr(0)
	}
}
