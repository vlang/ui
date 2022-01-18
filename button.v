// Copyright (c) 2020-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

import gx
import gg
import os

const (
	button_bg_color           = gx.rgb(28, 28, 28)
	button_border_color       = gx.rgb(200, 200, 200)
	button_focus_border_color = gx.rgb(50, 50, 50)
	button_horizontal_padding = 26
	button_vertical_padding   = 8
)

enum ButtonState {
	normal = 1 // synchronized with .button_normal
	pressed = 2
}

type ButtonClickFn = fn (voidptr, &Button) // state, btn

type ButtonKeyDownFn = fn (voidptr, &Button, u32)

[heap]
pub struct Button {
	// init size read-only
	width_  int
	height_ int
pub mut:
	id          string
	state       ButtonState = ButtonState(1)
	height      int
	width       int
	z_index     int
	x           int
	y           int
	offset_x    int
	offset_y    int
	text_width  int
	text_height int
	bg_color    &gx.Color = 0
	parent      Layout    = empty_stack
	is_focused  bool
	ui          &UI = 0
	onclick     ButtonClickFn
	// TODO: same convention for all callback
	on_key_down ButtonKeyDownFn = ButtonKeyDownFn(0)
	text        string
	icon_path   string
	image       gg.Image
	use_icon    bool
	padding     f32
	radius      f32
	hidden      bool
	movable     bool // drag, transition or anything allowing offset yo be updated
	hoverable   bool
	to_hover    bool
	tooltip     TooltipMessage
	// text styles
	text_styles TextStyles
	text_size   f64
	text_cfg    gx.TextCfg
	// theme
	theme_cfg ColorThemeCfg
	theme     map[int]gx.Color = map[int]gx.Color{}
	// component state for composable widget
	component voidptr
}

[params]
pub struct ButtonParams {
	id           string
	text         string
	icon_path    string
	onclick      ButtonClickFn
	on_key_down  ButtonKeyDownFn
	height       int
	width        int
	z_index      int
	movable      bool
	hoverable    bool
	tooltip      string
	tooltip_side Side = .top
	text_cfg     gx.TextCfg
	text_size    f64
	bg_color     &gx.Color     = 0
	theme        ColorThemeCfg = 'classic'
	radius       f64
	padding      f64
}

pub fn button(c ButtonParams) &Button {
	mut b := &Button{
		id: c.id
		width_: c.width
		height_: c.height
		z_index: c.z_index
		movable: c.movable
		hoverable: c.hoverable
		text: c.text
		icon_path: c.icon_path
		use_icon: c.icon_path != ''
		tooltip: TooltipMessage{c.tooltip, c.tooltip_side}
		bg_color: c.bg_color
		theme_cfg: if c.bg_color == voidptr(0) { c.theme } else { no_theme }
		onclick: c.onclick
		on_key_down: c.on_key_down
		text_cfg: c.text_cfg
		text_size: c.text_size
		radius: f32(c.radius)
		padding: f32(c.padding)
		ui: 0
	}
	if b.use_icon && !os.exists(c.icon_path) {
		println('Invalid icon path "$c.icon_path". The alternate text will be used.')
		b.use_icon = false
	}
	return b
}

fn (mut b Button) init(parent Layout) {
	b.parent = parent
	ui := parent.get_ui()
	b.ui = ui
	if b.use_icon {
		b.image = b.ui.gg.create_image(b.icon_path)
	}
	b.init_style()
	if b.tooltip.text != '' {
		mut win := ui.window
		win.append_tooltip(b, b.tooltip)
	}
	mut subscriber := parent.get_subscriber()
	subscriber.subscribe_method(events.on_key_down, btn_key_down, b)
	subscriber.subscribe_method(events.on_mouse_down, btn_mouse_down, b)
	subscriber.subscribe_method(events.on_click, btn_click, b)
	subscriber.subscribe_method(events.on_touch_down, btn_mouse_down, b)
	subscriber.subscribe_method(events.on_mouse_move, btn_mouse_move, b)
	subscriber.subscribe_method(events.on_mouse_up, btn_mouse_up, b)
	subscriber.subscribe_method(events.on_touch_up, btn_mouse_up, b)
	b.ui.window.evt_mngr.add_receiver(b, [events.on_mouse_down])
}

[manualfree]
fn (mut b Button) cleanup() {
	mut subscriber := b.parent.get_subscriber()
	subscriber.unsubscribe_method(events.on_key_down, b)
	subscriber.unsubscribe_method(events.on_mouse_down, b)
	subscriber.unsubscribe_method(events.on_click, b)
	subscriber.unsubscribe_method(events.on_touch_down, b)
	subscriber.unsubscribe_method(events.on_mouse_move, b)
	b.ui.window.evt_mngr.rm_receiver(b, [events.on_mouse_down])
	unsafe { b.free() }
}

[unsafe]
pub fn (b &Button) free() {
	$if free ? {
		print('button $b.id')
	}
	unsafe {
		b.id.free()
		b.text.free()
		b.icon_path.free()
		// s.onclick   ButtonClickFn
		b.tooltip.free()
		// s.theme     ColorThemeCfg = 'classic'

		// if b.component != voidptr(0) {
		// 	free(b.component)
		// }
		free(b)
	}
	$if free ? {
		println(' -> freed')
	}
}

fn (mut b Button) init_style() {
	$if nodtw ? {
		if is_empty_text_cfg(b.text_cfg) {
			b.text_cfg = b.ui.window.text_cfg
		}
		if b.text_size > 0 {
			_, win_height := b.ui.window.size()
			b.text_cfg = gx.TextCfg{
				...b.text_cfg
				size: text_size_as_int(b.text_size, win_height)
			}
		}
		set_text_cfg_align(mut b, .center)
		set_text_cfg_vertical_align(mut b, .middle)
	} $else {
		mut dtw := DrawTextWidget(b)
		dtw.init_style(align: .center, vertical_align: .middle)
		dtw.update_text_size(b.text_size)
	}
	b.set_text_size()
	b.update_theme()
}

fn btn_key_down(mut b Button, e &KeyEvent, window &Window) {
	// println('key down $e <$e.key> <$e.codepoint> <$e.mods>')
	// println('key down key=<$e.key> code=<$e.codepoint> mods=<$e.mods>')
	$if btn_keydown ? {
		println('btn_keydown: $b.id  -> $b.hidden $b.is_focused')
	}
	if b.hidden {
		return
	}
	if !b.is_focused {
		return
	}
	if b.on_key_down != ButtonKeyDownFn(0) {
		b.on_key_down(window.state, b, e.codepoint)
	} else {
		// default behavior like click for space and enter
		if e.key in [.enter, .space] {
			// println("btn key as a click")
			if b.onclick != ButtonClickFn(0) {
				b.onclick(window.state, b)
			}
		}
	}
}

fn btn_click(mut b Button, e &MouseEvent, window &Window) {
	// println('btn_click for window=$window.title')
	if b.hidden {
		return
	}
	$if wpir ? {
		println('btn click: $b.id ${b.ui.window.point_inside_receivers(events.on_mouse_down)}')
	}
	if !b.ui.window.is_top_widget(b, events.on_mouse_down) {
		return
	}
	if !b.is_focused {
		return
	}
	if b.point_inside(e.x, e.y) {
		if e.action == .down {
			b.state = .pressed
		} else if e.action == .up {
			b.state = .normal
			if b.onclick != ButtonClickFn(0) && b.is_focused {
				$if btn_onclick ? {
					println('onclick $b.id')
				}
				b.onclick(window.state, b)
			}
		}
	}
}

fn btn_mouse_down(mut b Button, e &MouseEvent, window &Window) {
	// println('btn_click for window=$window.title')
	if b.hidden {
		return
	}
	if !b.ui.window.is_top_widget(b, events.on_mouse_down) {
		return
	}
	if b.point_inside(e.x, e.y) {
		b.focus() // IMPORTANT to not propagate event at the same position of removed widget
		if b.movable {
			drag_register(b, b.ui, e)
		}
		b.state = .pressed
	}
}

fn btn_mouse_up(mut b Button, e &MouseEvent, window &Window) {
	// println('btn_click for window=$window.title')
	if b.hidden {
		return
	}
	b.state = .normal
}

fn btn_mouse_move(mut b Button, e &MouseMoveEvent, window &Window) {
	// println('btn_click for window=$window.title')
	if b.hidden {
		return
	}
	if e.mouse_button == 256 {
		if b.point_inside(e.x, e.y) {
			if b.hoverable && !b.to_hover {
				b.to_hover = true
			}
		} else {
			if b.hoverable && b.to_hover {
				b.to_hover = false
			}
			b.state = .normal
		}
	}
}

pub fn (mut b Button) set_pos(x int, y int) {
	b.x = x
	b.y = y
}

pub fn (mut b Button) size() (int, int) {
	if b.width == 0 || b.height == 0 {
		b.set_text_size()
	}
	return b.width, b.height
}

pub fn (mut b Button) propose_size(w int, h int) (int, int) {
	// println('prop size $w $h')
	if w != 0 {
		b.width = w
	}
	if h != 0 {
		b.height = h
	}
	// b.height = h
	// b.width = b.ui.ft.text_width(b.text) + ui.button_horizontal_padding
	// b.height = 20 // vertical padding
	// println("but prop size: $w, $h => $b.width, $b.height")
	update_text_size(mut b)
	return b.width, b.height
}

fn (mut b Button) draw() {
	offset_start(mut b)
	bcenter_x := b.x + b.width / 2
	bcenter_y := b.y + b.height / 2
	padding := relative_size(b.padding, b.width, b.height)
	x, y, width, height := b.x + padding, b.y + padding, b.width - 2 * padding, b.height - 2 * padding
	bg_color := if b.theme_cfg != no_theme {
		color(b.theme, if b.to_hover && b.state != .pressed { 3 } else { int(b.state) })
	} else if b.bg_color != voidptr(0) {
		*b.bg_color
	} else {
		gx.white
	}
	// println("bg:${b.to_hover} ${bg_color}")
	if b.radius > 0 {
		radius := relative_size(b.radius, int(width), int(height))
		b.ui.gg.draw_rounded_rect_filled(x, y, width, height, radius, bg_color) // gx.white)
		b.ui.gg.draw_rounded_rect_empty(x, y, width, height, radius, if b.is_focused {
			ui.button_focus_border_color
		} else {
			ui.button_border_color
		})
	} else {
		b.ui.gg.draw_rect_filled(x, y, width, height, bg_color) // gx.white)
		b.ui.gg.draw_rect_empty(x, y, width, height, if b.is_focused {
			ui.button_focus_border_color
		} else {
			ui.button_border_color
		})
	}
	if b.use_icon {
		b.ui.gg.draw_image(x, y, width, height, b.image)
	} else {
		$if nodtw ? {
			draw_text(b, bcenter_x, bcenter_y, b.text)
		} $else {
			dtw := DrawTextWidget(b)
			dtw.load_style()
			dtw.draw_text(bcenter_x, bcenter_y, b.text)
		}
	}
	$if tbb ? {
		println('bcenter_x($bcenter_x) = b.x($b.x) + b.width($b.width) / 2')
		println('bcenter_y($bcenter_y) = b.y($b.y) + b.height($b.height) / 2')
		println('draw_text(b, bcenter_x($bcenter_x), bcenter_y($bcenter_y), b.text($b.text))')
		println('draw_rect(b.x($b.x), b.y($b.y), b.width($b.width), b.height($b.height), bg_color)')
		draw_text_bb(bcenter_x, y, b.text_width, b.text_height, b.ui)
	}
	$if bb ? {
		draw_bb(mut b, b.ui)
	}
	offset_end(mut b)
}

pub fn (mut b Button) set_text(text string) {
	b.text = text
	b.set_text_size()
}

pub fn (mut b Button) set_text_size() {
	if b.use_icon {
		b.width = b.image.width
		b.height = b.image.height
	} else {
		b.text_width, b.text_height = text_size(b, b.text)
		// b.text_width = int(f32(b.text_width))
		// b.text_height = int(f32(b.text_height))
		b.width = b.text_width + ui.button_horizontal_padding
		if b.width_ > b.width {
			b.width = b.width_
		}
		b.height = b.text_height + ui.button_vertical_padding
		if b.height_ > b.height {
			b.height = b.height_
		}
	}
}

fn (b &Button) point_inside(x f64, y f64) bool {
	// println("point_inside button: ($b.x $b.offset_x, $b.y $b.offset_y) ($x, $y) ($b.width, $b.height)")
	return point_inside(b, x, y)
}

fn (mut b Button) set_visible(state bool) {
	b.hidden = !state
}

fn (mut b Button) focus() {
	mut f := Focusable(b)
	f.set_focus()
}

fn (mut b Button) unfocus() {
	b.is_focused = false
	b.state = .normal
}

pub fn (mut b Button) set_theme(theme_cfg ColorThemeCfg) {
	b.theme_cfg = theme_cfg
}

pub fn (mut b Button) update_theme() {
	update_colors_from(mut b.theme, theme(b), [1, 2, 3])
}
