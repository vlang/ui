## Applications as module

Application interface provide a way to develop an application as a self-content module. 
1) It is then possible to launch several same applications together that can interact with each other (see wm).
2) An application developed in a module can be also used as a simple application (see `example/apps` folder)

```{go}
import ui
import ui.apps.editor

fn main() {
	mut app := editor.app()
	app.run()
}
```