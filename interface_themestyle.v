module ui

interface WidgetThemeStyle {
	id string
mut:
	theme_style string
	load_style()
}

pub fn (mut w WidgetThemeStyle) update_theme_style(theme_style string) {
	w.theme_style = theme_style
}

pub fn (mut l Layout) update_theme_style(theme_style string) {
	for mut child in l.get_children() {
		if mut child is WidgetThemeStyle {
			mut w := child as WidgetThemeStyle
			w.update_theme_style(theme_style)
			// println("$w.id load style")
			w.load_style()
		}
		if mut child is Layout {
			mut w := child as Layout
			w.update_theme_style(theme_style)
		}
	}
}
