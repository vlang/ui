import ui
import ui.component as uic
import gx

const (
	win_width  = 800
	win_height = 600
)

fn main() {
	window := ui.window(
		width: win_width
		height: win_height
		title: 'V UI: TreeView'
		native_message: false
		mode: .resizable
		layout: ui.column(
			scrollview: true
			heights: ui.compact
			children: [
				uic.treeview_stack(
					id: 'demo'
					incr_mode: true
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
								uic.TreeItem('file: ftftyty2'),
								'file: hgyfyf2222',
							]
						},
					]
					icons: {
						'folder': 'tata'
						'file':   'toto'
					}
					text_color: gx.blue
					on_click: treeview_on_click
				),
			]
		)
	)
	ui.run(window)
}

fn treeview_on_click(c &ui.CanvasLayout, mut tv uic.TreeViewComponent) {
	selected := c.id
	println('${selected} selected with title: ${tv.titles[selected]}!')
}
