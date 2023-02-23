## Applications as module

Application interface provide a way to develop an application as a self-content module. 
1) It is then possible to launch several same applications together that can interact with each other (see wm).
2) An application developed in a module can be also used as a simple application (see `example/apps` folder)

```{go}
import ui
import ui.apps.editor

const (
	win_width   = 780
	win_height  = 395
)

fn main() {
	mut app := editor.new()
	app.window = ui.window(
		width: win_width
		height: win_height
		title: 'V UI Demo'
		mode: .resizable
		bg_color: ui.color_solaris
		native_message: false
	)
	app.run()
}
```