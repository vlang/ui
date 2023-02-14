module component

import ui
import gx

enum TabsMode {
	vertical
	horizontal
}

[heap]
pub struct TabsComponent {
pub mut:
	id                 string
	layout             &ui.Stack // required
	active             string
	prev_active        string
	tab_bar            &ui.Stack
	pages              map[string]ui.Widget
	z_index            map[string]int
	mode               TabsMode
	tab_width          f64
	tab_height         f64
	tab_spacing        f64
	bg_color           gx.Color = gx.white
	bg_color_selection gx.Color = gx.rgb(200, 200, 100)
	justify            []f64    = ui.center_center
}

[params]
pub struct TabsParams {
	id          string
	mode        TabsMode = .vertical
	active      int
	tabs        []string
	pages       []ui.Widget
	tab_width   f64 = 50.0
	tab_height  f64 = 30.0
	tab_spacing f64 = 5.0
}

// TODO: documentation
pub fn tabs_stack(c TabsParams) &ui.Stack {
	mut children := []ui.Widget{}

	for i, tab in c.tabs {
		println(tab_id(c.id, i) + '_label')
		children << ui.canvas_layout(
			id: tab_id(c.id, i)
			on_click: tab_click
			// bg_color: gx.white
			on_key_down: tab_key_down
			children: [
				ui.label(id: tab_id(c.id, i) + '_label', text: tab),
			]
		)
	}
	// Layout
	mut tab_bar := ui.row(
		id: '${c.id}_tabbar'
		widths: c.tab_width
		heights: c.tab_height
		spacing: c.tab_spacing
		children: children
	)

	mut m_pages := map[string]ui.Widget{}
	for i, page in c.pages {
		m_pages[tab_id(c.id, i)] = page
	}

	tab_active := tab_id(c.id, c.active)
	// println('active: $tab_active')

	mut layout := ui.column(
		id: ui.component_id(c.id, 'layout')
		widths: [ui.compact, ui.stretch]
		heights: [ui.compact, ui.stretch]
		children: [
			tab_bar,
			m_pages[tab_active],
		]
	)

	mut tabs := &TabsComponent{
		id: c.id
		layout: layout
		active: tab_active
		tab_bar: tab_bar
		pages: m_pages
		mode: c.mode
		tab_width: c.tab_width
		tab_height: c.tab_height
		tab_spacing: c.tab_spacing
	}

	for i, page in c.pages {
		if page is ui.Stack {
			tabs.z_index[tab_id(c.id, i)] = page.z_index
			ui.component_connect(tabs, page)
		} else if page is ui.CanvasLayout {
			tabs.z_index[tab_id(c.id, i)] = page.z_index
			ui.component_connect(tabs, page)
		}
		mut tab := tab_bar.children[i]
		if mut tab is ui.CanvasLayout {
			tab.update_style_params(
				bg_color: if i == 0 { tabs.bg_color_selection } else { tabs.bg_color }
			)
			ui.component_connect(tabs, tab)
		}
	}

	ui.component_connect(tabs, layout, tab_bar)
	// layout.on_build = tabs_build
	layout.on_init = tabs_init
	return layout
}

// TODO: documentation
pub fn tabs_component(w ui.ComponentChild) &TabsComponent {
	return unsafe { &TabsComponent(w.component) }
}

// TODO: documentation
pub fn tabs_component_from_id(w ui.Window, id string) &TabsComponent {
	return tabs_component(w.get_or_panic[ui.Stack](ui.component_id(id, 'layout')))
}

// fn tabs_build(layout &ui.Stack, win &ui.Window) {
// 	mut tabs := tabs_component(layout)
// 	tabs.update_pos(win)
// }

fn tabs_init(layout &ui.Stack) {
	mut tabs := tabs_component(layout)
	tabs.update_pos(layout.ui.window)
	for id, mut page in tabs.pages {
		println('tab ${id} initialized')
		if id != tabs.active {
			if mut page is ui.Layout {
				mut pa := page as ui.Layout
				tabs.layout.ui.window.register_children(mut pa.get_children())
			}
		}
		page.init(layout)
	}
	tabs.update_tab_colors()
	tabs.on_top()
	tabs.layout.update_layout()
	// println("${tabs.tab_bar.children.map(it.id)}")
	// tabs.print_styles()
}

fn tab_key_down(c &ui.CanvasLayout, e ui.KeyEvent) {
	if e.key in [.up, .down] {
		mut tabs := tabs_component(c)
		tabs.transpose()
	}
}

fn tab_click(c &ui.CanvasLayout, e ui.MouseEvent) {
	mut tabs := tabs_component(c)
	// println("selected $c.id")
	tabs.layout.children[1] = tabs.pages[c.id]
	tabs.layout.update_layout()
	win := tabs.layout.ui.window
	win.update_layout()
	// previous active
	tabs.prev_active = tabs.active
	// set current
	tabs.active = c.id
	tabs.update_tab_colors()
	tabs.on_top()
}

fn tab_id(id string, i int) string {
	return '${id}_tab_${i}'
}

fn (mut tabs TabsComponent) on_top() {
	for t, mut page in tabs.pages {
		// active
		if mut page is ui.Layout {
			mut l := page as ui.Layout
			if t == tabs.active {
				l.activate()
			} else {
				l.deactivate()
			}
			// l.update_drawing_children()
			// tabs.layout.ui.window.update_layout()
		}
	}
}

// fn (mut tabs TabsComponent) on_top() {
// 	for t, mut page in tabs.pages {
// 		incr := match t {
// 			tabs.active { 10 }
// 			tabs.prev_active { -10 }
// 			else { 0 }
// 		}
// 		// active
// 		if mut page is ui.Layout {
// 			mut l := page as ui.Layout
// 			l.incr_children_depth(incr)
// 			l.update_drawing_children()

// 		}
// 	}
// }

fn (mut tabs TabsComponent) update_tab_colors() {
	for mut tab in tabs.tab_bar.children {
		if mut tab is ui.CanvasLayout {
			color := if tab.id == tabs.active { tabs.bg_color_selection } else { tabs.bg_color }
			// println("$tab.id == $tabs.active -> $color")
			tab.update_style(bg_color: color)
			// println("$tab.id $tab.style.bg_color")
		}
	}
}

fn (mut tabs TabsComponent) print_styles() {
	for tab in tabs.tab_bar.children {
		if tab is ui.CanvasLayout {
			println('${tab.id} ${tab.style}')
		}
	}
}

fn (mut tabs TabsComponent) transpose() {
	if tabs.mode in [.vertical, .horizontal] {
		if tabs.mode == .vertical {
			tabs.mode = .horizontal
		} else {
			tabs.mode = .vertical
		}
		tabs.tab_bar.transpose(false)
		tabs.tab_bar.update_layout()
		tabs.layout.transpose(false)
		tabs.layout.update_layout()
	}
}

fn (tabs &TabsComponent) update_pos(win &ui.Window) {
	for i, _ in tabs.tab_bar.children {
		// println("$tabs.id ${tab_id(tabs.id, i) + "_label"}")
		lab_id := tab_id(tabs.id, i) + '_label'
		mut lab := win.get_or_panic[ui.Label](lab_id)
		lab.ui = win.ui
		mut dtw := ui.DrawTextWidget(lab)
		w, h := dtw.text_size(lab.text)
		// println(tabs.justify)
		// println("$lab.text ($w, $h) in (${int(tabs.tab_bar.widths[i])}, ${int(tabs.tab_bar.heights[i])})")
		dx, dy := ui.get_align_offset_from_size(w, h, int(tabs.tab_bar.widths[i]), int(tabs.tab_bar.heights[i]),
			tabs.justify[0], tabs.justify[1])
		// println("$dx, $dy $lab.x $lab.y")
		lab.set_pos(dx, dy)
		// println("$dx, $dy $lab.x $lab.y")
		mut c := win.get_or_panic[ui.CanvasLayout](tab_id(tabs.id, i))
		c.set_child_relative_pos(lab_id, dx, dy)
	}
}
