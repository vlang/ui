module explorer

import ui

@[heap]
pub struct AppEvents {
pub mut:
	id      string
	window  &ui.Window = unsafe { nil }
	layout  &ui.Layout = ui.empty_stack
	on_init ui.WindowFn
}

@[params]
pub struct AppEventsParams {
pub mut:
	id string
}

pub fn new(p AppEventsParams) &AppEvents {
	mut app := &AppEvents{
		id:    p.id
		users: p.users
	}
	app.make_layout()
	return app
}

pub fn app(p AppEventsParams) &ui.Application {
	app := new(p)
	return &ui.Application(app)
}

pub fn (mut app AppEvents) make_layout() {
}
