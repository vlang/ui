import ui
import ui.apps.users
import ui.apps.editor
import ui.apps.v2048

fn main() {
	mut wm := ui.wm(mode: .max_size, kind: .free)
	mut app := users.new()
	mut app2 := editor.new()
	mut app3 := v2048.new()
	wm.add('appusers: (0,0) ++ (0.3,0.5)', mut app)
	wm.add('editor: (0.3,0) -> (1,1)', mut app2)
	wm.add('v2048: (0,0.5) ++ (0.3,0.5)', mut app3)
	wm.run()
}
