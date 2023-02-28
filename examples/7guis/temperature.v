import ui
import regex
import gx
import math

const (
	win_width  = 400
	win_height = 41
)

fn main() {
	window := ui.window(
		width: win_width
		height: win_height
		title: 'Temperature Converter'
		mode: .resizable
		layout: ui.row(
			margin_: 10
			spacing: 10
			widths: [ui.stretch, ui.compact, ui.stretch, ui.compact]
			heights: 20.0
			children: [
				ui.textbox(
					id: 'celsius'
					on_change: on_change_celsius
				),
				ui.label(text: 'Celsius = '),
				ui.textbox(
					id: 'fahren'
					on_change: on_change_fahren
				),
				ui.label(text: 'Fahrenheit'),
			]
		)
	)
	ui.run(window)
}

fn on_change_celsius(mut tb_celsius ui.TextBox) {
	mut tb_fahren := tb_celsius.ui.window.get_or_panic[ui.TextBox]('fahren')
	if tb_celsius.text.len <= 0 {
		tb_fahren.set_text('0')
		return
	}
	if is_number(*(tb_celsius.text)) {
		celsius := (*(tb_celsius.text)).f64()
		fahren := celsius * (9.0 / 5.0) + 32.0
		tb_fahren.set_text((math.ceil(fahren * 100) / 100.0).str())
		tb_celsius.update_style(bg_color: gx.white)
	} else {
		tb_celsius.update_style(bg_color: gx.orange)
	}
}

fn on_change_fahren(mut tb_fahren ui.TextBox) {
	mut tb_celsius := tb_fahren.ui.window.get_or_panic[ui.TextBox]('celsius')
	if tb_fahren.text.len <= 0 {
		tb_celsius.set_text('0')
		return
	}
	if is_number(*(tb_fahren.text)) {
		fah := (*tb_fahren.text).f64()
		cel := (fah - 32.0) * (5.0 / 9.0)
		tb_celsius.set_text((math.ceil(cel * 100) / 100.0).str())
		tb_fahren.update_style(bg_color: gx.white)
	} else {
		tb_fahren.update_style(bg_color: gx.orange)
	}
}

fn is_number(txt string) bool {
	query := r'\-?(?P<before>\d+)\.?(?P<after>\d+)?'
	mut re := regex.regex_opt(query) or { panic(err) }
	return re.matches_string(txt)
}
