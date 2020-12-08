module webview

// #flag linux -I /usr/include/glib-2.0
// #flag linux -I /usr/include/gtk-3.0
// #flag linux -I /usr/include/webkitgtk-4.0
#flag linux -I /usr/include/harfbuzz
#pkgconfig gtk+-3.0 webkit2gtk-4.0
#include <gtk/gtk.h>
#include <webkit2/webkit2.h>

// struct C.GtkWidget{}

fn C.gtk_init()

// fn C.webkit_web_view_new()

fn new_linux_web_view() {
	C.gtk_init()
	// C.webkit_web_view_new()
}
