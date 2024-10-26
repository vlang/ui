module v2048

import ui
import ui.component as uic

@[heap]
pub struct AppUI {
pub mut:
	id      string
	window  &ui.Window  = unsafe { nil }
	layout  &ui.Layout  = ui.empty_stack
	on_init ui.WindowFn = unsafe { nil }
	// s
	app &App = unsafe { nil }
}

@[params]
pub struct AppUIParams {
pub mut:
	id  string = 'v2048'
	app &App   = unsafe { nil }
}

pub fn new(p AppUIParams) &AppUI {
	mut app := &AppUI{
		id: p.id
	}
	app.make_layout()
	return app
}

pub fn app(p AppUIParams) &ui.Application {
	app := new(p)
	return &ui.Application(app)
}

pub fn (mut app AppUI) make_layout() {
	app.app = new_ui_app()
	app.layout = uic.gg_canvaslayout(
		id:  ui.id(app.id, 'ui_app')
		app: app.app
	)
	app.on_init = fn (w &ui.Window) {
		// // add shortcut for hmenu
		// uic.hideable_add_shortcut(w, 'ctrl + o', fn [mut app] (w &ui.Window) {
		// 	uic.hideable_toggle(w, ui.id(app.id, 'hmenu'))
		// })
		// // At first hmenu open
		// uic.hideable_show(w, ui.id(app.id, 'hmenu'))
	}
}
