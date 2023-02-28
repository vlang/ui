// Same as demo_component_filebrowser with folder_only: true
import ui
import ui.component as uic

const (
	win_width  = 800
	win_height = 600
)

fn main() {
	window := ui.window(
		width: win_width
		height: win_height
		title: 'V UI: File Browser'
		native_message: false
		mode: .resizable
		layout: uic.filebrowser_stack(
			id: 'fb'
			on_click_ok: on_click_ok
			on_click_cancel: on_click_cancel
			folder_only: true
		)
	)
	ui.run(window)
}

fn on_click_ok(b &ui.Button) {
	println(uic.filebrowser_component(b).selected_full_title())
}

fn on_click_cancel(b &ui.Button) {
	if b.ui.dd is ui.DrawDeviceContext {
		b.ui.dd.quit()
	}
}
