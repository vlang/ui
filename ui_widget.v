module ui

pub fn get_depth(w &Widget) int {
	return w.z_index
}

pub fn set_depth(mut w Widget, z_index int) {
	w.z_index = z_index
	// w.set_visible(z_index != ui.z_index_hidden)
}

// TODO: If id is added to Widget interface,
// this could be simplified and above all extensible with external widgets
pub fn (child &Widget) id() string {
	match child {
		Button, Canvas, CheckBox, Dropdown, Grid, Label, ListBox, Menu, Picture, ProgressBar,
		Radio, Rectangle, Slider, Switch, TextBox, Transition, Stack, Group, CanvasLayout {
			return child.id
		}
		else {
			return '_unknown'
		}
	}
}
