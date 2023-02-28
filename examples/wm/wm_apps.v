import ui
import ui.apps.users
import ui.apps.editor

fn main() {
	mut wm := ui.wm()
	mut app := users.new()
	wm.add('appusers: (20,20) ++ (600,400)', mut app)
	mut app2 := editor.new()
	wm.add('editor: (400,10) ++ (600,400)', mut app2)
	wm.run()
}
