// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

pub struct Label {
mut:
	text   string
	parent ILayouter
	x      int
	y      int
	ui     &UI
}

pub struct LabelConfig {
	text   string
}

fn (l mut Label)init(p &ILayouter) {
	parent := *p
	ui := parent.get_ui()
	l.ui = ui
}

pub fn label(c LabelConfig) &Label {
	return &Label{
		text: c.text
	}
}

fn (b mut Label) set_pos(x, y int) {
	b.x = x
	b.y = y
}

fn (b mut Label) propose_size(w, h int) (int, int) {
	//b.width = w
	//b.height = h
	return b.ui.ft.text_size(b.text)
}

fn (b mut Label) draw() {
	b.ui.ft.draw_text(b.x, b.y, b.text, btn_text_cfg)
}

fn (t &Label) focus() {}

fn (t &Label) is_focused() bool {
	return false
}

fn (t &Label) unfocus() {}

fn (t &Label) point_inside(x, y f64) bool {
	return false // x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}

pub fn (l mut Label) set_text(s string) {
	l.text = s
}
