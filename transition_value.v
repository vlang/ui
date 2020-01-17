// Copyright (c) 2020 Leah Lundqvist. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

pub struct TransitionValue {
mut:
	parent 			 &ui.Window
	idx    			 int
	ui     			 &UI
}

pub struct TransitionValueConfig {
	parent   		 &ui.Window
}

pub fn new_transition_value(config TransitionValueConfig) &TransitionValue {
	mut transition := &TransitionValue{
		parent: config.parent
		ui: config.parent.ui
	}
	transition.parent.children << transition
	return transition
}

fn (b mut TransitionValue) draw() {

} 

fn (t &TransitionValue) key_down(e KeyEvent) {}

fn (t &TransitionValue) click(e MouseEvent) {}

fn (t &TransitionValue) focus() {}

fn (t &TransitionValue) idx() int {
	return t.idx
}

fn (t &TransitionValue) is_focused() bool {
	return false
}

fn (t &TransitionValue) unfocus() {}

fn (t &TransitionValue) point_inside(x, y f64) bool {
	return false // x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}

fn (t mut TransitionValue) mouse_move(e MouseEvent) { }

fn (t &TransitionValue) typ() WidgetType {
	return .transition_value
}