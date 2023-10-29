module ui

pub interface WidgetBuild {
mut:
	id string
	ui &UI
	build(mut win Window)
}

// pub fn (l Layout) build_(win &Window) {
// 	for mut w in l.get_children() {
// 		if mut w is  WidgetBuild {
// 			mut wb := w as WidgetBuild
// 			wb.build(win)
// 		}
// 		if w is Layout {
// 			wl := w as Layout
// 			wl.build_(win)
// 		}
// 	}
// }

// TODO: documentation
pub fn (mut win Window) build_layout(l Layout) {
	for mut w in l.get_children() {
		if mut w is WidgetBuild {
			mut wb := w as WidgetBuild
			wb.build(mut win)
		}
		if mut w is Layout {
			mut wl := w as Layout
			win.build_layout(wl)
		}
	}
}

// TODO: documentation
pub fn (mut win Window) build() {
	win.build_layout(win)
}
