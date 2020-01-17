// Copyright (c) 2020 Leah Lundqvist. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui
import time

pub struct TransitionValue {
mut:
	last_draw_time	i64
	started_time		i64
	duration				i64
	animating				bool
	parent 			 		&ui.Window
	animated_value 	&int
	start_value 		int
	target_value 		int
	idx    			 		int
	ui     			 		&UI
}

pub struct TransitionValueConfig {
	duration 			 	int
	animated_value 	&int
	parent   		 		&ui.Window
}

pub fn new_transition_value(config TransitionValueConfig) &TransitionValue {
	mut transition := &TransitionValue{
		last_draw_time: time.ticks()
		started_time: 0
		duration: config.duration
		animating: false
		animated_value: config.animated_value
		start_value: *config.animated_value
		target_value: *config.animated_value
		parent: config.parent
		ui: config.parent.ui
	}
	transition.parent.children << transition
	return transition
}

fn (t mut TransitionValue) draw() {
	if t.target_value != *t.animated_value && !t.animating {
		t.animating = true
		t.started_time = time.ticks()
		t.start_value = *t.animated_value
	}

	if t.animating {
		x := f32(time.ticks() - t.started_time + 1) / f32(t.duration)

		mut mapped := t.start_value + int((if x<.5 { 2.0*x*x } else { -1.0+(4.0-2.0*x)*x }) * f32(t.target_value - t.start_value))

		if x >= 1 {
			t.animating = false
			mapped = t.target_value
		}

		*t.animated_value = mapped
		
		t.last_draw_time = time.ticks()
	}
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