module ui

import gg
import gx

// // fn (tb &TextBox) draw_inner_border() {
// fn draw_inner_border(border_accentuated bool, gg &gg.Context, x int, y int, width int, height int, is_error bool) {
// 	if !border_accentuated {
// 		color := if is_error { gx.rgb(255, 0, 0) } else { ui.text_border_color }
// 		gg.draw_rect_empty(x, y, width, height, color)
// 		// gg.draw_rect_empty(tb.x, tb.y, tb.width, tb.height, color) //ui.text_border_color)
// 		// TODO this should be +-1, not 0.5, a bug in gg/opengl
// 		gg.draw_rect_empty(0.5 + f32(x), 0.5 + f32(y), width - 1, height - 1, ui.text_inner_border_color) // inner lighter border
// 	} else {
// 		gg.draw_rect_empty(x, y, width, height, ui.text_border_accentuated_color)
// 		gg.draw_rect_empty(1.5 + f32(x), 1.5 + f32(y), width - 3, height - 3, ui.text_border_accentuated_color) // inner lighter border
// 	}
// }

// fn (tb &TextBox) draw_inner_border() {
fn draw_device_inner_border(border_accentuated bool, d gg.DrawDevice, x int, y int, width int, height int, is_error bool) {
	if !border_accentuated {
		color := if is_error { gx.rgb(255, 0, 0) } else { text_border_color }
		d.draw_rect_empty(x, y, width, height, color)
		// gg.draw_rect_empty(tb.x, tb.y, tb.width, tb.height, color) //ui.text_border_color)
		// TODO this should be +-1, not 0.5, a bug in gg/opengl
		d.draw_rect_empty(0.5 + f32(x), 0.5 + f32(y), width - 1, height - 1, text_inner_border_color) // inner lighter border
	} else {
		d.draw_rect_empty(x, y, width, height, text_border_accentuated_color)
		d.draw_rect_empty(1.5 + f32(x), 1.5 + f32(y), width - 3, height - 3, text_border_accentuated_color) // inner lighter border
	}
}
