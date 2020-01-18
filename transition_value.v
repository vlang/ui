// Copyright (c) 2020 Leah Lundqvist. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui
import time

pub struct TransitionValue {
mut:
	last_draw_time   i64
	started_time     i64
	duration         i64
	animating        bool
	easing           EasingFunction
	parent           &ui.Window
	animated_value   &int
	start_value      int
	target_value     int
	last_draw_target int
	idx              int
	ui               &UI
}

pub struct TransitionValueConfig {
	duration       int
	animated_value &int
	easing         EasingFunction
	parent         &ui.Window
}

pub fn new_transition_value(config TransitionValueConfig) &TransitionValue {
	mut transition := &TransitionValue{
		last_draw_time: time.ticks()
		started_time: 0
		duration: config.duration
		animating: false
		easing: config.easing
		animated_value: config.animated_value
		start_value: *config.animated_value
		target_value: *config.animated_value
		last_draw_target: *config.animated_value
		parent: config.parent
		ui: config.parent.ui
	}
	transition.parent.children << transition
	return transition
}

fn (t mut TransitionValue) draw() {
	if t.target_value != *t.animated_value && !t.animating {
		// Initiate the transition by setting start_time to the current time
		// and set the start value to the current value of the transition target.
		t.started_time = time.ticks()
		t.start_value = *t.animated_value
		t.animating = true
	} else if t.animating && t.target_value != t.last_draw_target {
		// Update the target and restart time if target changes
		// while it's still animating the previous value change.
		t.started_time = time.ticks()
		t.start_value = *t.animated_value
	}
	if t.animating {
		// Get the current progress of start_time -> start_time+duration
		x := f32(time.ticks() - t.started_time + 1) / f32(t.duration)
		// Map the progress value [0 -> 1] to [0 -> delta value]
		// Using the defined EasingFunction
		mut mapped := t.start_value + int(t.easing(x) * f64(t.target_value - t.start_value))
		// Animation finished
		if x >= 1 {
			t.animating = false
			mapped = t.target_value
		}
		// Update the target value and request a redraw
		*t.animated_value = mapped
		t.ui.redraw_requested = true
		// Set last_draw_target to check for target_value changes between renders.
		t.last_draw_target = t.target_value
		// Update last draw time to calculate frame delta
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
	return false
}

fn (t mut TransitionValue) mouse_move(e MouseEvent) { }

fn (t &TransitionValue) typ() WidgetType {
	return .transition_value
}