import ui
import ui.apps.users
import ui.apps.editor
import ui.apps.v2048

fn main() {
	mut wm := ui.wm(
		apps: {
			'appusers: (20,20) ++ (600,400)': users.new()
			'editor: (400,10) ++ (600,400)':  editor.new()
			'v2048: (100,100) ++ (600,400)':  v2048.new()
		}
	)
	wm.run()
}
