// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

pub fn message_box(s string) {
	unsafe {
		ns_string := nsstring(s)
		#NSAlert *alert = [[NSAlert alloc] init] ;
		#[alert setMessageText:ns_string];
		#[alert runModal];
		_ = ns_string // hide warning
	}
}

fn nsstring(s string) voidptr {
	unsafe {
		#return [ [ NSString alloc ] initWithBytesNoCopy:s.str  length:s.len
		#encoding:NSUTF8StringEncoding freeWhenDone: false];
	}
	return 0
}

pub fn notify(title string, msg string) {
	unsafe {
		ns_msg := nsstring(msg)
		ns_title := nsstring(title)
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
	s := ''
	#s = tos2( [[[NSBundle mainBundle] bundlePath] UTF8String]);
	return s
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
