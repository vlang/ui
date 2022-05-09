import ui
import ui.component as uic

fn main() {
	mut vars := {
		'A': uic.GridData([''].repeat(100))
	}
	// from B to Z
	for i in 66 .. (66 + 25) {
		vars[[u8(i)].bytestr()] = uic.GridData([''].repeat(100))
	}
	mut v_a := vars['A'] or { []string{} }
	if mut v_a is []string {
		v_a[0] = 'Sum B2:C5 = '
	}
	mut v_b := vars['B'] or { []string{} }
	if mut v_b is []string {
		v_b[1] = '12'
		v_b[2] = '1'
		v_b[3] = '1'
		v_b[4] = '23'
	}
	mut v_c := vars['C'] or { []string{} }
	if mut v_c is []string {
		v_c[1] = '13'
		v_c[2] = '-1'
		v_c[3] = '31'
		v_c[4] = '2'
	}
	window := ui.window(
		width: 600
		height: 400
		title: 'Cells'
		mode: .resizable
		children: [
			ui.row(
				spacing: 5
				margin_: 10
				widths: ui.stretch
				heights: ui.stretch
				children: [
					uic.datagrid_stack(
						id: 'dgs'
						vars: vars
						formulas: {
							'B1': '=sum(B2:C5)'
						}
						is_focused: true
					),
				]
			),
		]
	)
	ui.run(window)
}
