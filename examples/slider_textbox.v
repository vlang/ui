import ui

const ( win_width = 650		win_height = 450 )

struct App {
   mut:
	window			&ui.Window
	vert_slider		ui.Slider
	vert_textbox	ui.TextBox
	hor_slider		ui.Slider	
	hor_textbox		ui.TextBox
}

fn main() {
	mut app := &App{ window: 0 }

	win_cfg				:= ui.WindowConfig{ width: win_width, height: win_height, title: 'Slider Example', user_ptr: app }

	slider_row_cfg		:= ui.RowConfig{ alignment: .top, margin: ui.MarginConfig{ 100, 30, 30, 30 }, spacing: 30 }

	textbox_row_cfg		:= ui.RowConfig{ alignment: .top, margin: ui.MarginConfig{ 50, 115, 30, 30 }, spacing: 100 }

	vert_slider_min := -100		vert_slider_max := -20		vert_slider_val := (vert_slider_max + vert_slider_min)/2
	vert_slider_cfg		:= ui.SliderConfig{ width: 10, height: 200, orientation: .vertical
							min: vert_slider_min, max: vert_slider_max, val: vert_slider_val
							focus_on_thumb_only: true, rev_min_max_pos: true
							on_value_changed: on_vert_value_changed, ref: &app.vert_slider }
	
	hor_slider_min := -20		hor_slider_max := 100		hor_slider_val := (hor_slider_max + hor_slider_min)/2
	hor_slider_cfg		:= ui.SliderConfig{ width: 200, height: 10, orientation: .horizontal
							min: hor_slider_min, max: hor_slider_max, val: hor_slider_val
							focus_on_thumb_only: true, rev_min_max_pos: true
							on_value_changed: on_hor_value_changed, ref: &app.hor_slider }

	hor_textbox_cfg		:= ui.TextBoxConfig{ width:40, height: 20, max_len: 20, read_only: true, is_numeric: true
							text: hor_slider_val.str(), ref: &app.hor_textbox }

	vert_textbox_cfg	:= ui.TextBoxConfig{ width:40, height: 20, max_len: 20, read_only: true, is_numeric: true
							text: vert_slider_val.str(), ref: &app.vert_textbox }
	
	window := ui.window( win_cfg,
	  [
		ui.iwidget( ui.row(textbox_row_cfg,
			[
				ui.iwidget( ui.textbox( hor_textbox_cfg ) ),
				ui.iwidget( ui.textbox( vert_textbox_cfg ) )
			] )
		),
		
		ui.iwidget( ui.row( slider_row_cfg,
			[
				ui.iwidget( ui.slider( hor_slider_cfg ) ),
				ui.iwidget( ui.slider( vert_slider_cfg ) )
			] )
		)
	  ]
	)
	app.window = window
	ui.run( window )
}

fn on_hor_value_changed( app mut App ) {
	app.hor_textbox.text = int( app.hor_slider.val ).str()
}

fn on_vert_value_changed( app mut App ) {
	app.vert_textbox.text = int( app.vert_slider.val ).str()
}
