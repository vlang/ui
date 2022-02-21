module component

import ui
import gx

enum TabsMode {
	vertical
	horizontal
}

[heap]
struct Tabs {
pub mut:
	id          string
	layout      &ui.Stack // required
	active      string
	tab_bar     &ui.Stack
	pages       map[string]ui.Widget
	mode        TabsMode
	tab_width   f64
	tab_height  f64
	tab_spacing f64
	// To become a component of a parent component
	component voidptr
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

pub fn tabs(c TabsParams) &ui.Stack {
	mut children := []ui.Widget{}

	for i, tab in c.tabs {
		children << ui.canvas_layout(
			id: tab_id(c.id, i)
			on_click: tab_click
			on_key_down: tab_key_down
			children: [
				ui.at(0, 0, ui.label(text: tab)),
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
	println('active: $tab_active')

	mut layout := ui.column(
		id: c.id
		widths: [ui.compact, ui.stretch]
		heights: [ui.compact, ui.stretch]
		children: [
			tab_bar,
			m_pages[tab_active],
		]
	)

	mut tabs := &Tabs{
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
			ui.component_connect(tabs, page)
		} else if page is ui.CanvasLayout {
			ui.component_connect(tabs, page)
		}
		mut tab := tab_bar.children[i]
		if mut tab is ui.CanvasLayout {
			ui.component_connect(tabs, tab)
		}
	}

	ui.component_connect(tabs, layout, tab_bar)
	layout.component_init = tabs_init
	return layout
}

pub fn component_tabs(w ui.ComponentChild) &Tabs {
	return &Tabs(w.component)
}

fn tabs_init(layout &ui.Stack) {
	mut tabs := component_tabs(layout)
	for id, mut page in tabs.pages {
		println('tab $id initialized')
		page.init(layout)
	}
	tabs.update_tab_colors()
	// set width and height of tab
	// for mut tab in tabs.tab_bar.children {
	// 	tab.width =
	// }
	tabs.layout.update_layout()
}

fn tab_key_down(e ui.KeyEvent, c &ui.CanvasLayout) {
	if e.key in [.up, .down] {
		mut tabs := component_tabs(c)
		tabs.transpose()
	}
}

fn tab_click(e ui.MouseEvent, c &ui.CanvasLayout) {
	mut tabs := component_tabs(c)
	// println("selected $c.id")
	tabs.layout.children[1] = tabs.pages[c.id]
	tabs.layout.update_layout()
	win := tabs.layout.ui.window
	win.update_layout()
	// set current
	tabs.active = c.id
	tabs.update_tab_colors()
}

fn tab_id(id string, i int) string {
	return '${id}_tab_$i'
}

fn (tabs &Tabs) update_tab_colors() {
	for tab in tabs.tab_bar.children {
		if mut tab is ui.CanvasLayout {
			color := if tab.id == tabs.active { gx.rgb(200, 200, 100) } else { gx.white }
			// println("$tab.id == $tabs.active -> $color")
			tab.bg_color = color
		}
	}
}

fn (mut tabs Tabs) transpose() {
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
