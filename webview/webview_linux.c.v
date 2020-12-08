module webview

#flag linux -I /usr/include/harfbuzz
#pkgconfig gtk+-3.0 webkit2gtk-4.0
#include <gtk/gtk.h>
#include <webkit2/webkit2.h>

struct C.GtkWidget{}

fn C.gtk_init(argc int, argv voidptr)

fn C.gtk_window_new() &C.GtkWidget{}

fn C.gtk_window_set_default_size(win C.GtkWidget, w int, h int)

fn C.gtk_widget_show_all(win C.GtkWidget)

fn C.gtk_main()

fn C.g_signal_connect(ins voidptr, signal string, cb voidptr, data voidptr)

fn C.gtk_main_quit()

// fn C.webkit_web_view_new()

fn new_linux_web_view() {
	C.gtk_init(0, voidptr(0))
	win := C.gtk_window_new(0)
	C.gtk_window_set_default_size(win, 1000, 600)
	C.g_signal_connect(win, 'destroy', destroy_window_cb, voidptr(0))
	C.gtk_widget_show_all(win)
	C.gtk_main()
	// C.webkit_web_view_new()
}

fn destroy_window_cb(widget voidptr, window voidptr) {
	C.gtk_main_quit()
}
