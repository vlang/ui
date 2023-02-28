import ui
import ui.apps.users
import ui.apps.editor
import ui.apps.v2048

fn main() {
	mut wm := ui.wm()
	mut app := users.new()
	wm.add('appusers: (20,20) ++ (600,400)', mut app)
	mut app2 := editor.new()
	wm.add('editor: (400,10) ++ (600,400)', mut app2)
	mut app3 := v2048.new()
	wm.add('v2048: (100,100) ++ (600,400)', mut app3)
	wm.run()
}
