// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

[heap]
pub struct Label {
mut:
	text   string
	parent Layout
	x      int
	y      int
	ui     &UI
}

pub struct LabelConfig {
	text string
}

fn (mut l Label) init(parent Layout) {
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

fn (mut l Label) set_pos(x int, y int) {
	l.x = x
	l.y = y
}

fn (mut l Label) size() (int, int) {
	// println("size $l.text")
	mut w, mut h := l.ui.gg.text_size(l.text)
	// RCqls: Not Sure at all, just a guess visiting fontstash
	// TODO: Change it if text_size is updated
	$if macos {
		h = int(f32(h) * l.ui.gg.scale * l.ui.gg.scale)
		// println("label size: $w $h2")

		// First return the width, then the height multiplied by line count.
		w = int(f32(w) * l.ui.gg.scale * l.ui.gg.scale)
	}
	return w, h * l.text.split('\n').len
}

fn (mut l Label) propose_size(w int, h int) (int, int) {
	ww, hh := l.ui.gg.text_size(l.text)
	// First return the width, then the height multiplied by line count.
	return ww, hh * l.text.split('\n').len
}

fn (mut l Label) draw() {
	splits := l.text.split('\n') // Split the text into an array of lines.
	height := l.ui.gg.text_height('W') // Get the height of the current font.
	for i, split in splits {
		// Draw the text at l.x and l.y + line height * current line
		l.ui.gg.draw_text(l.x, l.y + (height * i), split, btn_text_cfg)
	}
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

pub fn (mut l Label) set_ui(ui &UI) {
	l.ui = ui
}
