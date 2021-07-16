module ui

// Widget having a field is_focused
pub fn (w Widget) is_focusable() bool {
	return w.type_name() in ['ui.Button', 'ui.CanvasLayout', 'ui.CheckBox', 'ui.Dropdown',
		'ui.ListBox', 'ui.Radio', 'ui.Slider', 'ui.Switch', 'ui.TextBox']
}

// Only one widget can have the focus inside a Window
pub fn set_focus<T>(w &Window, mut f T) {
	if f.is_focused() {
		return
	}
	w.unfocus_all()
	if Widget(f).is_focusable() {
		f.is_focused = true
	}
}
