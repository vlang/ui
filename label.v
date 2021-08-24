// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx

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
	ui         &UI
	text_cfg   gx.TextCfg
	text_size  f64
	hidden     bool
	// component state for composable widget
	component voidptr
}

pub struct LabelConfig {
	id        string
	width     int
	height    int
	z_index   int
	text      string
	text_cfg  gx.TextCfg
	text_size f64
}

pub fn label(c LabelConfig) &Label {
	lbl := &Label{
		id: c.id
		text: c.text
		width: c.width
		height: c.height
		ui: 0
		z_index: c.z_index
		text_size: c.text_size
		text_cfg: c.text_cfg
	}
	return lbl
}

fn (mut l Label) init(parent Layout) {
	ui := parent.get_ui()
	l.ui = ui
	if is_empty_text_cfg(l.text_cfg) {
		l.text_cfg = l.ui.window.text_cfg
	}
	if l.text_size > 0 {
		_, win_height := l.ui.window.size()
		l.text_cfg = gx.TextCfg{
			...l.text_cfg
			size: text_size_as_int(l.text_size, win_height)
		}
	}
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

fn (mut l Label) set_pos(x int, y int) {
	l.x = x
	l.y = y
}

fn (mut l Label) adj_size() (int, int) {
	if l.adj_width == 0 || l.adj_height == 0 {
		// println("size $l.text")
		w, h := text_size(l, l.text)
		// println("label size: $w, $h ${l.text.split('\n').len}")
		l.adj_width, l.adj_height = w, h * l.text.split('\n').len
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
	offset_start(mut l)
	splits := l.text.split('\n') // Split the text into an array of lines.
	l.ui.gg.set_cfg(l.text_cfg)
	height := l.ui.gg.text_height('W') // Get the height of the current font.
	for i, split in splits {
		// Draw the text at l.x and l.y + line height * current line
		// l.ui.gg.draw_text(l.x, l.y + (height * i), split, l.text_cfg.as_text_cfg())
		// l.draw_text(l.x, l.y + (height * i), split)
		draw_text(l, l.x, l.y + (height * i), split)
		$if tbb ? {
			w, h := l.ui.gg.text_width(split), l.ui.gg.text_height(split)
			println('label: w, h := l.ui.gg.text_width(split), l.ui.gg.text_height(split)')
			println('draw_text_bb(l.x($l.x), l.y($l.y) + (height($height) * i($i)), w($w), h($h), l.ui)')
			draw_text_bb(l.x, l.y + (height * i), w, h, l.ui)
		}
	}
	$if bb ? {
		draw_bb(mut l, l.ui)
	}
	offset_end(mut l)
}

fn (mut l Label) set_visible(state bool) {
	l.hidden = !state
}

fn (l &Label) point_inside(x f64, y f64) bool {
	return false // x >= l.x && x <= l.x + l.width && y >= l.y && y <= l.y + l.height
}

pub fn (mut l Label) set_text(s string) {
	l.text = s
}
