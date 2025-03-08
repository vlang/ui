module webview

#flag linux -I /usr/include/harfbuzz
#pkgconfig gtk4
#pkgconfig webkit2gtk-4.0
#include <gtk/gtk.h>
#include <webkit2/webkit2.h>

struct C.GtkWidget {
}

fn C.gtk_init(argc int, argv voidptr)

fn C.gtk_window_new() &C.GtkWidget

fn C.gtk_window_set_default_size(win C.GtkWidget, w int, h int)

fn C.gtk_window_set_title(win C.GtkWidget, title &char)

fn C.gtk_container_add(container voidptr, widget voidptr)

fn C.gtk_widget_show_all(win C.GtkWidget)

fn C.gtk_main()

fn C.g_signal_connect(ins voidptr, signal string, cb voidptr, data voidptr)

fn C.gtk_widget_destroy(widget voidptr)

fn C.gtk_widget_grab_focus(widget voidptr)

fn C.gtk_main_quit()

struct C.WebKitWebView {
}

fn C.webkit_web_view_new() &C.WebKitWebView

fn C.webkit_web_view_load_uri(webview voidptr, uri &char)

fn create_linux_web_view(url string, title string) {
	C.gtk_init(0, unsafe { nil })
	win := C.gtk_window_new()
	C.gtk_window_set_default_size(win, 1000, 600)
	C.gtk_window_set_title(win, &char(title.str))
	webview := C.webkit_web_view_new()
	C.gtk_container_add(win, webview)
	C.g_signal_connect(win, 'destroy', destroy_window_cb, unsafe { nil })
	C.g_signal_connect(webview, 'close', destroy_window_cb, win)
	C.webkit_web_view_load_uri(webview, &char(url.str))
	C.gtk_widget_grab_focus(webview)
	C.gtk_widget_show_all(win)
	C.gtk_main()
}

fn destroy_window_cb(widget voidptr, window voidptr) {
	C.gtk_main_quit()
}

fn close_webview_cb(webview voidptr, window voidptr) bool {
	C.gtk_widget_destroy(window)
	return true
}
