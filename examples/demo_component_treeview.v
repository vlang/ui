import ui
import ui.component as uic
// import gx

const (
	win_width  = 800
	win_height = 600
)

struct App {
mut:
	window &ui.Window
}

fn main() {
	mut app := &App{
		window: 0
	}
	window := ui.window(
		width: win_width
		height: win_height
		title: 'V UI: TreeView'
		state: app
		native_message: false
		children: [
			uic.treeview(
				id: 'demo'
				trees: [
					uic.Tree{
						title: 'toto1'
						items: [
							uic.TreeItem('file: ftftyty1'),
							'file: hgyfyf1',
							uic.Tree{
								title: 'tttytyty1'
								items: [
									uic.TreeItem('file: tutu2'),
									'ytytyy2',
								]
							},
						]
					},
					uic.Tree{
						title: 'toto2'
						items: [
							uic.TreeItem('file: ftftyty1'),
							'file: hgyfyf1111',
						]
					},
				]
				icons: {
					'folder': 'tata'
					'file':   'toto'
				}
			),
		]
	)
	app.window = window
	ui.run(window)
}
