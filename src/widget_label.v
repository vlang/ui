// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gg

[heap]
pub struct Label {
pub mut:
	id         string
	text       string
	parent     Layout = empty_stack
	x          int
	y          int
	offset_x   int
	offset_y   int
	width      int
	height     int
	z_index    int
	adj_width  int
	adj_height int
	justify    []f64
	ui         &UI = unsafe { nil }
	// Style
	theme_style  string
	style        LabelStyle
	style_params LabelStyleParams
	// text styles
	text_styles TextStyles
	// text_size   f64
	hidden bool
	// component state for composable widget
	component voidptr
}

[params]
pub struct LabelParams {
	LabelStyleParams
	id      string
	width   int
	height  int
	z_index int
	justify []f64 = [0.0, 0.0]
	text    string
	// text_size f64
	theme string = no_style
}

pub fn label(c LabelParams) &Label {
	mut lbl := &Label{
		id: c.id
		text: c.text
		width: c.width
		height: c.height
		ui: 0
		z_index: c.z_index
		// text_size: c.text_size
		justify: c.justify
		style_params: c.LabelStyleParams
	}
	lbl.style_params.style = c.theme
	return lbl
}

fn (mut l Label) init(parent Layout) {
	ui := parent.get_ui()
	l.ui = ui
	l.load_style()
	// l.init_style()
	l.init_size()
}

[manualfree]
pub fn (mut l Label) cleanup() {
	unsafe { l.free() }
}

[unsafe]
pub fn (l &Label) free() {
	$if free ? {
		print('label $l.id')
	}
	unsafe {
		l.id.free()
		l.text.free()
		free(l)
	}
	$if free ? {
		println(' -> freed')
	}
}

// fn (mut l Label) init_style() {
// 	mut dtw := DrawTextWidget(l)
// 	dtw.init_style()
// 	dtw.update_text_size(l.text_size)
// }

pub fn (mut l Label) set_pos(x int, y int) {
	l.x = x
	l.y = y
}

fn (mut l Label) adj_size() (int, int) {
	if l.adj_width == 0 || l.adj_height == 0 {
		dtw := DrawTextWidget(l)
		// println(dtw.current_style().size)
		dtw.load_style()
		mut w, mut h := 0, 0
		if !l.text.contains('\n') {
			w, h = dtw.text_width(l.text), dtw.current_style().size
			// println("$w, $h, $l.text ${dtw.text_height(l.text)}")
		} else {
			for line in l.text.split('\n') {
				wi, he := dtw.text_size(line)
				if wi > w {
					w = wi
				}
				h += he
			}
		}

		// println("label size: $w, $h ${l.text.split('\n').len}")
		l.adj_width, l.adj_height = w, h
	}
	return l.adj_width, l.adj_height
}

fn (mut l Label) init_size() {
	if l.width == 0 {
		l.width, _ = l.adj_size()
	}
	if l.height == 0 {
		_, l.height = l.adj_size()
	}
}

fn (l &Label) size() (int, int) {
	return l.width, l.height
}

fn (mut l Label) propose_size(w int, h int) (int, int) {
	l.width, l.height = w, h
	return l.size()
}

fn (mut l Label) draw() {
	l.draw_device(l.ui.gg)
}

fn (mut l Label) draw_device(d DrawDevice) {
	offset_start(mut l)
	$if layout ? {
		if l.ui.layout_print {
			println('Label($b.id): ($l.x, $l.y, $l.width, $l.height)')
		}
	}
	splits := l.text.split('\n') // Split the text into an array of lines.
	height := l.ui.gg.text_height('W') // Get the height of the current font.
	for i, split in splits {
		dtw := DrawTextWidget(l)
		dtw.draw_device_load_style(d)
		dtw.draw_device_text(d, l.x, l.y + (height * i), split)
		$if tbb ? {
			w, h := l.ui.gg.text_width(split), l.ui.gg.text_height(split)
			println('label: w, h := l.ui.gg.text_width(split), l.ui.gg.text_height(split)')
			println('debug_draw_bb_text(l.x($l.x), l.y($l.y) + (height($height) * i($i)), w($w), h($h), l.ui)')
			debug_draw_bb_text(l.x, l.y + (height * i), w, h, l.ui)
		}
	}
	$if bb ? {
		debug_draw_bb_widget(mut l, l.ui)
	}
	offset_end(mut l)
}

fn (mut l Label) set_visible(state bool) {
	l.hidden = !state
}

pub fn (l &Label) point_inside(x f64, y f64) bool {
	return x >= l.x && x <= l.x + l.width && y >= l.y && y <= l.y + l.height
}

pub fn (mut l Label) set_text(s string) {
	l.text = s
}
