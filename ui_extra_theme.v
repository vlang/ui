module ui

import gx

enum ColorType {
	button_normal = 1
	button_pressed
}

struct Color {
	id    ColorType
	color gx.Color
}

type ColorTheme = map[int]gx.Color

type ColorThemes = map[string]ColorTheme

type ColorThemeCfg = ColorTheme | string

// create new color theme
pub fn color_theme(items ...Color) ColorTheme {
	mut theme := map[int]gx.Color{}
	for item in items {
		theme[int(item.id)] = item.color
	}
	return theme
}

// register color theme
pub fn (mut w Window) register_color_theme(name string, theme ColorTheme) {
	w.color_themes[name] = theme
}

fn (mut w Window) register_default_color_themes() {
	w.color_themes['classic'] = color_theme(Color{.button_normal, gx.white}, Color{.button_pressed, gx.rgb(219,
		219, 219)})
	w.color_themes['red'] = color_theme(Color{.button_normal, gx.light_red}, Color{.button_pressed, gx.rgb(219,
		0, 0)})
	w.color_themes['blue'] = color_theme(Color{.button_normal, gx.light_blue}, Color{.button_pressed, gx.blue})
}

pub fn color(theme map[int]gx.Color, id ColorType) gx.Color {
	return theme[int(id)]
}

pub fn set_color(mut theme map[int]gx.Color, id ColorType, color gx.Color) {
	theme[int(id)] = color
}

pub fn update_colors_from(mut theme map[int]gx.Color, theme2 map[int]gx.Color, ids []ColorType) {
	for id in ids {
		theme[int(id)] = theme2[int(id)]
	}
}
