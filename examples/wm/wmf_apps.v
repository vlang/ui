import ui
import ui.apps.users
import ui.apps.editor

fn main() {
	mut wm := ui.wmf(mode: .max_size)
	mut app := users.new()
	wm.add('appusers: (0,0) ++ (0.3,1)', mut app)
	mut app2 := editor.new()
	wm.add('editor: (0.3,0) -> (1,1)', mut app2)
	wm.run()
}
