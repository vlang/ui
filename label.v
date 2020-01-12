// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx
import freetype

pub struct Label {
mut:
	text   string
	parent &ui.Window
	x      int
	y      int
	idx    int
	ctx    &UI
}

pub struct LabelConfig {
	x      int
	y      int
	parent &ui.Window
	text   string
}

pub fn new_label(c LabelConfig) &Label {
	mut l := &Label{
		text: c.text
		x: c.x
		y: c.y
		parent: c.parent
		ctx: c.parent.ctx
	}
	l.parent.children << l
	return l
}

fn (b mut Label) draw() {
	b.ctx.ft.draw_text(b.x, b.y, b.text, btn_text_cfg)
}

fn (t &Label) key_down(e KeyEvent) {}

fn (t &Label) click(e MouseEvent) {
}

fn (t &Label) focus() {}

fn (t &Label) idx() int {
	return t.idx
}

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
