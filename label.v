// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx

[heap]
pub struct Label {
mut:
	text      string
	parent    Layout
	x         int
	y         int
	z_index   int
	ui        &UI
	text_cfg  gx.TextCfg
	text_size f64
	hidden    bool
}

pub struct LabelConfig {
	z_index   int
	text      string
	text_cfg  gx.TextCfg
	text_size f64
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
}

pub fn label(c LabelConfig) &Label {
	lbl := &Label{
		text: c.text
		ui: 0
		z_index: c.z_index
	}
	return lbl
}

fn (mut l Label) set_pos(x int, y int) {
	l.x = x
	l.y = y
}

fn (mut l Label) size() (int, int) {
	// println("size $l.text")
	mut w, mut h := text_size<Label>(l, l.text)
	// println("label size: $w, $h ${l.text.split('\n').len}")
	return w, h * l.text.split('\n').len
}

fn (mut l Label) propose_size(w int, h int) (int, int) {
	ww, hh := text_size<Label>(l, l.text)
	// First return the width, then the height multiplied by line count.
	return ww, hh * l.text.split('\n').len
}

fn (mut l Label) draw() {
	splits := l.text.split('\n') // Split the text into an array of lines.
	l.ui.gg.set_cfg(l.text_cfg)
	height := l.ui.gg.text_height('W') // Get the height of the current font.
	for i, split in splits {
		// Draw the text at l.x and l.y + line height * current line
		// l.ui.gg.draw_text(l.x, l.y + (height * i), split, l.text_cfg.as_text_cfg())
		// l.draw_text(l.x, l.y + (height * i), split)
		draw_text<Label>(l, l.x, l.y + (height * i), split)
		$if tbb ? {
			w, h := l.ui.gg.text_width(split), l.ui.gg.text_height(split)
			println('label: w, h := l.ui.gg.text_width(split), l.ui.gg.text_height(split)')
			println('draw_text_bb(l.x($l.x), l.y($l.y) + (height($height) * i($i)), w($w), h($h), l.ui)')
			draw_text_bb(l.x, l.y + (height * i), w, h, l.ui)
		}
	}
	$if bb ? {
		draw_bb(l, l.ui)
	}
}

fn (mut l Label) set_visible(state bool) {
	l.hidden = state
}

fn (l &Label) focus() {
}

fn (l &Label) is_focused() bool {
	return false
}

fn (l &Label) unfocus() {
}

fn (l &Label) point_inside(x f64, y f64) bool {
	return false // x >= l.x && x <= l.x + l.width && y >= l.y && y <= l.y + l.height
}

pub fn (mut l Label) set_text(s string) {
	l.text = s
}
