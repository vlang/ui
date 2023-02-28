import ui
import ui.apps.users
import ui.apps.editor
import ui.apps.v2048

fn main() {
	mut wm := ui.wm(
		mode: .max_size
		kind: .free
		apps: {
			'appusers: (0,0) ++ (0.3,0.5)': users.new()
			'editor: (0.3,0) -> (1,1)':     editor.new()
			'v2048: (0,0.5) ++ (0.3,0.5)':  v2048.new()
		}
	)
	wm.run()
}
