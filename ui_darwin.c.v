// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

#include "@VROOT/ui_darwin.m"

fn C.nsstring(s string)
fn C.bundle_path()

pub fn message_box(s string) {
	unsafe {
		ns_string := C.nsstring(s)
		#NSAlert *alert = [[NSAlert alloc] init] ;
		#[alert setMessageText:ns_string];
		#[alert runModal];
		_ = ns_string // hide warning
	}
}

pub fn notify(title string, msg string) {
	unsafe {
		ns_msg := C.nsstring(msg)
		ns_title := C.nsstring(title)
		#NSUserNotification *notification = [[[NSUserNotification alloc] init] retain];
		#notification.title = ns_title;
		#notification.informativeText = ns_msg;
		#NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
		#[center deliverNotification:notification];
		_ = ns_msg
		_ = ns_title
	}
}

/*
pub fn text_width(s string) int {
	return 0
}
*/
pub fn bundle_path() string {
	return C.bundle_path()
}

pub fn wait_events() {
	unsafe {
		#NSEvent *event = [NSApp nextEventMatchingMask:NSEventMaskAny
		#untilDate:[NSDate distantFuture]
		#inMode:NSDefaultRunLoopMode
		#dequeue:YES];
		#[NSApp sendEvent:event];
	}
}
