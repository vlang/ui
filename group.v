// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx
import eventbus

pub struct Group {
pub mut:

    title          string
    height         int
    width          int
    x              int
    y              int
    parent Layout
    ui             &UI
    children []Widget
    margin_left int = 5
    margin_top int = 10
    margin_right int = 5
    margin_bottom int = 5
    spacing int = 5
}

pub struct GroupConfig {
pub mut:
    title  string
    x          int
    y          int
    width  int
    height int
    children []Widget
}

fn (mut r Group)init(parent Layout) {
    r.parent = parent
    ui := parent.get_ui()
    r.ui = ui

    for child in r.children {
        child.init(r)
    }

    mut widgets := r.children
    mut start_x := r.x + r.margin_left
    mut start_y := r.y + r.margin_top
    for widget in widgets {
        mut pw, ph := widget.size()
        widget.set_pos(start_x, start_y)
        start_y = start_y + ph + r.spacing
        if pw > r.width - r.margin_left - r.margin_right {
            r.width = pw + r.margin_left + r.margin_right
        }
        if start_y + r.margin_bottom > r.height {
            r.height = start_y -ph
        }
    }
}

pub fn group(c GroupConfig) &Group {
    mut cb := &Group{
        title: c.title
        x: c.x
        y:c.y
        width: c.width
        height: c.height
        children: c.children
		ui: 0
    }
    return cb
}

fn (mut g Group) set_pos(x, y int) {
    g.x = x
    g.y = y
}

fn (mut g Group) propose_size(w, h int) (int, int) {
    g.width = w
    g.height = h
    return g.width, g.height
}

fn (mut b Group) draw() {
    // Border
    b.ui.gg.draw_empty_rect(f32(b.x), f32(b.y), f32(b.width), f32(b.height), gx.gray)
    // Title
    b.ui.gg.draw_rect(f32(b.x + check_mark_size), f32(b.y) - 5, f32(b.ui.ft.text_width(b.title)) + 5, 10, default_window_color)
    b.ui.ft.draw_text_def(b.x + check_mark_size + 3, b.y - 7, b.title)

    for child in b.children {
        child.draw()
    }
}

fn (t &Group) point_inside(x, y f64) bool {
    return x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}

fn (mut b Group) focus() {
}

fn (mut b Group) unfocus() {
}

fn (t &Group) is_focused() bool {
    return false
}

fn (t &Group) get_ui() &UI {
    return t.ui
}

fn (t &Group) unfocus_all() {
    for child in t.children {
        child.unfocus()
    }
}

fn (t &Group) resize(width, height int) {
}

fn (t &Group) get_state() voidptr {
    parent := t.parent
    return parent.get_state()
}

fn (b &Group) get_subscriber() &eventbus.Subscriber {
    parent := b.parent
    return parent.get_subscriber()
}

fn (c &Group) size() (int, int) {
    return c.width, c.height
}
