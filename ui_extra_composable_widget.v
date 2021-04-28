module ui

// Composable Widget
/*
Since there is no inheritance in v

[[Example]]: <<RowWidget>> replaced with Real Name of Composable Stacked Widget

struct <<RowWidget>> {
	layout &Stack
	tb TextBox
	label LabelConfig
}

Proposition 1
-------------

pub struct <<RowWidget>>Config {
  layout RowConfig
  tb TextBoxConfig
  l LabelConfig
}

pub fn <<row_widget>>(cfg <<RowWidget>>Config) {
	cfg_tb := {
		...cfg.tb		
		// internal stuff here
		// callbacks
		// private setting
	}
	tb := textbox(cfg_tb)

	cfg_l := {
		...cfg.l
		// internal stuff here
		// callbacks
		// private setting
	}
	l := label(cfg.l)
	layout := row(cfg.layout, [tb, l])
	composable_widget := &<<RowWidget>>{
		layout: layout
		tb: tb
		label: label
	}
	layout.composable_widget = composable_widget
	return layout
}
*/

/*
Proposition 2
-------------

pub struct <<RowWidget>>Config {
	// layout field
	row_<<field1>>
	...
	// label field
   	l_<<field1>>
   	....
	// textbox field
   	tb_<<field1>>
   	....
}

pub fn <<row_widget>>(cfg <<RowWidget>>Config) {

	tb := textbox({
		<<field1>>: cfg.tb_<<field1>>
		...
		// internal stuff here
		// callbacks
		// internal settings
	})

	l := label({
		<<field1>>: cfg.l_<<field1>>
	})

	layout := row(cfg.layout, [tb, l])
	composable_widget := &<<RowWidget>>{
		layout: layout
		tb: tb
		l: l
	}
	layout.composable_widget = composable_widget
	return layout // since drawing system
}
*/

/*
How to manipulate it ?

1) Add: row_init callback to init component children inside composable widget
=> This approach provides initial change after registration and init of component children
2) Declaration of methods:

fn (mut w <<RowWidget>>) <<method>>(...) {
	layout := w.layout // if needed
}

3) From the window, the composable widget is avalaible by id or from its parent layout. But direct access from id seems better.

4) callback can be already added to component widgets.
*/

interface ComposableWidget {
mut:
	component voidptr
}
