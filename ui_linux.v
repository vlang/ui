// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

/*
#include <gtk/gtk.h>
#flag `pkg-config --cflags gtk+-3.0` `pkg-config --libs gtk+-3.0`

struct C.GtkWidget{}
struct C.GtkDialog{}
type Callback fn (voidptr)
fn C.g_signal_connect_swapped(inst &GtkWidget, signal charptr, cb Callback, obj &GtkWidget)
fn C.gtk_init(int, &charptr)
fn C.gtk_main()
fn C.gtk_main_quit()
fn C.gtk_message_dialog_new(voidptr, int, int, int, charptr) &GtkWidget
fn C.gtk_widget_show(w &GtkWidget)
fn C.gtk_widget_destroy(w &GtkWidget)

fn message_box_close(w &GtkWidget){
	C.gtk_widget_destroy(w)
	C.gtk_main_quit()
}
*/

pub fn message_box(s string) {
	// TODO
	/*
	gtk_init(0, [''].data)
	dialog := C.gtk_message_dialog_new( 0, C.GTK_DIALOG_DESTROY_WITH_PARENT, C.GTK_MESSAGE_INFO, C.GTK_BUTTONS_OK, s.str)
	C.g_signal_connect_swapped( dialog, 'response'.str, message_box_close as Callback, dialog )
	C.gtk_widget_show(dialog)
	C.gtk_main()
	*/
}
