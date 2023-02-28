import ui.apps.v2048

// This code is not really V UI related
// It is just a consequence of 2048 packaged as a module
// However, the package is complete enough to be called inside VUI
// see examples/component/gg2048.v

fn main() {
	mut app := v2048.new()
	app.run()
}
