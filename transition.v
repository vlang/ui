// Copyright (c) 2020 Leah Lundqvist. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui
import time

pub struct Transition {
//pub:
mut:
	last_draw_time   i64
	started_time     i64
	duration         i64
	animating        bool
	easing           EasingFunction
	parent           Layout
	start_value      int
	last_draw_target int
	ui               &UI
pub mut:
	target_value     int
	animated_value   &int
}

pub struct TransitionConfig {
	duration       int
	animated_value &int = 0
	easing         EasingFunction
	ref				&Transition = 0
}

fn (mut t Transition) init(parent Layout) {
	t.parent = parent
	ui := parent.get_ui()
	t.ui = ui
}

pub fn transition(config TransitionConfig) &Transition {
	mut transition := &Transition{
		last_draw_time: time.ticks()
		started_time: 0
		duration: config.duration
		animating: false
		easing: config.easing
		ui: 0
		animated_value: 0
	}
	return transition
}

pub fn (mut t Transition) set_value(animated_value &int){
	t.animated_value = animated_value
	t.start_value = *animated_value
	t.target_value =  *animated_value
	t.last_draw_target = *animated_value
}

fn (t &Transition) set_pos(x, y int) {}
fn (t &Transition) propose_size(w, h int) (int, int) {
	return 0,0
}

fn (mut b Transition) size() (int, int) {
	return 0,0
}

fn (mut t Transition) draw() {
	if t.animated_value == 0 {return}
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
		(*t.animated_value) = mapped
		t.ui.redraw_requested = true
		// Set last_draw_target to check for target_value changes between renders.
		t.last_draw_target = t.target_value
		// Update last draw time to calculate frame delta
		t.last_draw_time = time.ticks()
	}
}

fn (t &Transition) focus() {}

fn (t &Transition) is_focused() bool {
	return false
}

fn (t &Transition) unfocus() {}

fn (t &Transition) point_inside(x, y f64) bool {
	return false
}
