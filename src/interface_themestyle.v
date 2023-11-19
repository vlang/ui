module ui

pub interface WidgetThemeStyle {
	id string
mut:
	theme_style string
	load_style()
}

// TODO: documentation
pub fn (mut w WidgetThemeStyle) update_theme_style(theme_style string) {
	w.theme_style = theme_style
}

// TODO: documentation
pub fn (mut l Layout) update_theme_style(theme_style string) {
	if mut l is WidgetThemeStyle {
		mut w := mut l as WidgetThemeStyle
		w.update_theme_style(theme_style)
		// println("$w.id update_theme_style load style")
		w.load_style()
	}
	for mut child in l.get_children() {
		if mut child is Layout {
			mut w := child as Layout
			w.update_theme_style(theme_style)
		}
		if mut child is WidgetThemeStyle {
			mut w := mut child as WidgetThemeStyle
			w.update_theme_style(theme_style)
			// println('$w.id update_theme_style load style')
			w.load_style()
		}
	}
}
