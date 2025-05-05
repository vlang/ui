## Applications as module

Application interface provide a way to develop an application as a self-content module. 
1) It is then possible to launch several same applications together that can interact with each other (see wm).
```v
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
```
2) An application developed in a module can be also used as a simple application (see `example/apps` folder)

```v
import ui.apps.editor

fn main() {
	mut app := editor.app()
	app.run()
}
```
