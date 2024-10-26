module ui

import sokol.sgl
import sokol.sfons

// Rmk: Some sort of replacement of text stuff inside ui_extra_draw.v
pub interface DrawTextWidget {
	id string
mut:
	ui          &UI
	text_styles TextStyles
}

// TODO: documentation
pub fn (mut w DrawTextWidget) add_font(font_name string, font_path string) {
	w.ui.add_font(font_name, font_path)
}

// TODO: documentation
pub fn (mut w DrawTextWidget) init_style(ts TextStyleParams) {
	w.set_current_style(ts)
}

// TODO: documentation
pub fn (w &DrawTextWidget) text_style(ts TextStyleParams) TextStyle {
	ts_ := if ts.id == no_string { w.text_styles.current } else { w.style_by_id(ts.id) }
	return TextStyle{
		...ts_
		size:           if ts.size < 0 { ts_.size } else { ts.size }
		font_name:      if ts.font_name == no_string { ts_.font_name } else { ts.font_name }
		color:          if ts.color == no_color { ts_.color } else { ts.color }
		align:          if ts.align == .@none { ts_.align } else { ts.align }
		vertical_align: if ts.vertical_align == .@none {
			ts_.vertical_align
		} else {
			ts.vertical_align
		}
	}
}

// define style to be used with drawtext method
pub fn (mut w DrawTextWidget) add_style(ts TextStyle) {
	mut id := ts.id
	if id == '' {
		if ts.font_name == '' {
			eprintln('Warning: nothing done in add_style since id or font_name missing')
			return
		}
		id = ts.font_name
	}
	w.text_styles.hash[id] = TextStyle{
		id:             id
		font_name:      ts.font_name
		color:          ts.color
		size:           ts.size
		align:          ts.align
		vertical_align: ts.vertical_align
		mono:           ts.mono
	}
	// println(w.text_styles.hash)
}

// pub fn (w2 DrawTextWidget) update_style2(ts TextStyleParams) {
// 	mut w := w2
// 	mut ts_ := if ts.id in w.text_styles.hash {
// 		&(w.text_styles.hash[ts.id])
// 	} else {
// 		&(w.text_styles.current)
// 	}
// 	unsafe {
// 		*ts_ = TextStyle{
// 			...(*ts_)
// 			size: if ts.size < 0 { ts_.size } else { ts.size }
// 			font_name: if ts.font_name == no_string { ts_.font_name } else { ts.font_name }
// 			color: if ts.color == no_color { ts_.color } else { ts.color }
// 			align: if ts.align == .@none { ts_.align } else { ts.align }
// 			vertical_align: if ts.vertical_align == .@none {
// 				ts_.vertical_align
// 			} else {
// 				ts.vertical_align
// 			}
// 		}
// 	}
// }

// TODO: documentation
pub fn (mut w DrawTextWidget) update_style(ts TextStyleParams) {
	mut ts_ := if ts.id in w.text_styles.hash {
		&(w.text_styles.hash[ts.id])
	} else {
		&(w.text_styles.current)
	}
	unsafe {
		*ts_ = TextStyle{
			...(*ts_)
			size:           if ts.size < 0 { ts_.size } else { ts.size }
			font_name:      if ts.font_name == no_string { ts_.font_name } else { ts.font_name }
			color:          if ts.color == no_color { ts_.color } else { ts.color }
			align:          if ts.align == .@none { ts_.align } else { ts.align }
			vertical_align: if ts.vertical_align == .@none {
				ts_.vertical_align
			} else {
				ts.vertical_align
			}
		}
	}
}

// TODO: documentation
pub fn (mut w DrawTextWidget) update_text_size(size f64) {
	if size > 0 {
		_, win_height := w.ui.window.size()
		// ts := w.text_styles.current
		// ts.size = text_size_as_int(size, win_height)
		w.text_styles.current = TextStyle{
			...w.text_styles.current
			size: text_size_as_int(size, win_height)
		}
	}
}

// TODO: documentation
pub fn (w &DrawTextWidget) style_by_id(id string) TextStyle {
	return w.text_styles.hash[id] or { w.ui.text_styles[id] or { w.ui.text_styles['_default_'] } }
}

// current style
pub fn (w &DrawTextWidget) current_style() TextStyle {
	return w.text_styles.current
}

// TODO: documentation
pub fn (mut w DrawTextWidget) set_current_style(ts TextStyleParams) {
	w.text_styles.current = w.text_style(ts)
}

// TODO: documentation
pub fn (mut w DrawTextWidget) load_style_(d DrawDevice, ts TextStyle) {
	// println("load style ${w.style_id()} $ts")
	if d.has_text_style() {
		// println('lds current style: $ts')
		// println('d.set_text_style($ts.font_name, $ts.size, $ts.color, ${int(ts.align)}, ${int(ts.vertical_align)})')
		d.set_text_style(ts.font_name, w.ui.font_paths[ts.font_name], ts.size, ts.color,
			int(ts.align), int(ts.vertical_align))
	}
	$if !screenshot ? {
		if mut w.ui.dd is DrawDeviceContext {
			gg_ := w.ui.dd
			fons := gg_.ft.fons
			fons.set_font(w.ui.fonts.hash[ts.font_name])

			scale := if gg_.ft.scale == 0 { f32(1) } else { gg_.ft.scale }
			size := if ts.mono { ts.size - 2 } else { ts.size }
			fons.set_size(scale * f32(size))
			gg_.ft.fons.set_align(int(ts.align) | int(ts.vertical_align))
			color := sfons.rgba(ts.color.r, ts.color.g, ts.color.b, ts.color.a)
			if ts.color.a != 255 {
				sgl.load_pipeline(gg_.pipeline.alpha)
			}
			gg_.ft.fons.set_color(color)
			ascender := f32(0.0)
			descender := f32(0.0)
			lh := f32(0.0)
			fons.vert_metrics(&ascender, &descender, &lh)
			// println("load style $ascender, $descender ${}")
		}
	}
}

// TODO: documentation
pub fn (w &DrawTextWidget) font_size() int {
	return w.current_style().size
}

// TODO: documentation
pub fn (mut w DrawTextWidget) load_style() {
	w.draw_device_load_style(w.ui.dd)
}

// Draw and size methods

// TODO: documentation
pub fn (mut w DrawTextWidget) draw_device_load_style(d DrawDevice) {
	ts := w.current_style()
	// println("lds $w.id current style: $ts")
	w.load_style_(d, ts)
}

// TODO: documentation
pub fn (w &DrawTextWidget) draw_device_text(d DrawDevice, x int, y int, text string) {
	d.draw_text_default(x, y, text)
}

// TODO: documentation
pub fn (mut w DrawTextWidget) draw_device_styled_text(d DrawDevice, x int, y int, text string, ts TextStyleParams) {
	w.load_style_(d, w.text_style(ts))
	d.draw_text_default(x, y, text)
}

// TODO: documentation
pub fn (w &DrawTextWidget) text_size(text string) (int, int) {
	dd := w.ui.dd
	return dd.text_size(text)
}

// TODO: documentation
pub fn (w &DrawTextWidget) text_width(text string) int {
	dd := w.ui.dd
	return dd.text_width(text)
}

// TODO: documentation
pub fn (w &DrawTextWidget) text_width_additive(text string) f64 {
	dd := w.ui.dd
	if dd is DrawDeviceContext {
		return dd.text_width_additive(text)
	} else {
		return w.text_width(text)
	}
}

// TODO: documentation
pub fn (w &DrawTextWidget) text_height(text string) int {
	dd := w.ui.dd
	return dd.text_height(text)
}

pub fn (w &DrawTextWidget) text_bounds(x int, y int, text string) []f32 {
	dd := w.ui.dd
	return if dd is DrawDeviceContext {
		dd.text_bounds(x, y, text)
	} else {
		[]f32{}
	}
}
