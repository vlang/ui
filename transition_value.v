// Copyright (c) 2020 Leah Lundqvist. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui
import time

pub struct TransitionValue {
mut:
	last_draw		 		int
	parent 			 		&ui.Window
	animated_value 	&int
	interp_value 	 	f32
	target_value 		int
	idx    			 		int
	ui     			 		&UI
}

pub struct TransitionValueConfig {
	speed 			 		int
	animated_value 	&int
	parent   		 		&ui.Window
}

pub fn new_transition_value(config TransitionValueConfig) &TransitionValue {
	mut transition := &TransitionValue{
		last_draw: time.ticks()
		animated_value: config.animated_value
		interp_value: f32(*config.animated_value)
		target_value: *config.animated_value
		parent: config.parent
		ui: config.parent.ui
	}
	transition.parent.children << transition
	return transition
}

fn (t mut TransitionValue) draw() {

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