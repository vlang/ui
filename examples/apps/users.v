import ui
import ui.apps.users

fn main() {
	mut app := users.app()
	app.add_window(
		width:    780
		height:   395
		title:    'V UI Demo'
		mode:     .resizable
		bg_color: ui.color_solaris
		// theme: 'red'
		native_message: false
	)
	app.run()
}
