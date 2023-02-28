import ui
import ui.apps.users

const (
	win_width  = 780
	win_height = 395
)

fn main() {
	mut app := users.app()
	app.add_window(
		width: win_width
		height: win_height
		title: 'V UI Demo'
		mode: .resizable
		bg_color: ui.color_solaris
		// theme: 'red'
		native_message: false
	)
	app.run()
}
