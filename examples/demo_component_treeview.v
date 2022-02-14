import ui
import ui.component as uic
import gx

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
		mode: .resizable
		children: [
			ui.column(
				scrollview: true
				heights: ui.compact
			children: [uic.treeview(
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
									'file: ytytyy2',
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
					uic.Tree{
						title: 'toto3'
						items: [
							uic.TreeItem('file: ftftyty1'),
							'file: hgyfyf1111',
						]
					},
					uic.treedir("/Users/rcqls/GitHub/ui")
				]
				icons: {
					'folder': 'tata'
					'file':   'toto'
				}
				text_color: gx.blue
				on_click: treeview_onclick
			)]
			)
		]
	)
	app.window = window
	ui.run(window)
}

fn treeview_onclick(selected string, mut tv uic.TreeView) {
	println('$selected selected with title: ${tv.titles[selected]}!')
}
