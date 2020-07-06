// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

[ref_only]
pub struct Label {
mut:
	text   string
	parent Layout
	x      int
	y      int
	ui     &UI
}

pub struct LabelConfig {
	text   string
}

fn (mut l Label)init(parent Layout) {
	ui := parent.get_ui()
	l.ui = ui
}

pub fn label(c LabelConfig) &Label {
	lbl := &Label{
		text: c.text
		ui: 0
	}
	return lbl
}

fn (mut b Label) set_pos(x, y int) {
	b.x = x
	b.y = y
}

fn (mut b Label) size() (int, int) {
	w,h := b.ui.gg.text_size(b.text)

	// First return the width, then the height multiplied by line count.
	return w, h * b.text.split('\n').len
}

fn (mut b Label) propose_size(w, h int) (int, int) {
	ww,hh := b.ui.gg.text_size(b.text)

	// First return the width, then the height multiplied by line count.
	return ww, hh * b.text.split('\n').len
}

fn (mut b Label) draw() {
	splits := b.text.split('\n') // Split the text into an array of lines.
	height := b.ui.gg.text_height('W') // Get the height of the current font.

	for i, split in splits {
		// Draw the text at b.x and b.y + line height * current line
		b.ui.gg.draw_text(b.x, b.y + (height * i), split, btn_text_cfg)
	}
}

fn (t &Label) focus() {}

fn (t &Label) is_focused() bool {
	return false
}

fn (t &Label) unfocus() {}

fn (t &Label) point_inside(x, y f64) bool {
	return false // x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}

pub fn (mut l Label) set_text(s string) {
	l.text = s
}
