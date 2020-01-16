// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

[unsafe_fn]
pub fn message_box(s string) {
	ns_string := nsstring(s)
	# NSAlert *alert = [[NSAlert alloc] init] ;
	# [alert setMessageText:ns_string];
	# [alert runModal];
}

[unsafe_fn]
fn nsstring(s string) voidptr {
	# return [ [ NSString alloc ] initWithBytesNoCopy:s.str  length:s.len
	# encoding:NSUTF8StringEncoding freeWhenDone: false];
	return 0
}

[unsafe_fn]
pub fn notify(title, msg string) {
	ns_msg := nsstring(msg)
	ns_title := nsstring(title)
	# NSUserNotification *notification = [[[NSUserNotification alloc] init] retain];
	# notification.title = ns_title;
	# notification.informativeText = ns_msg;
	# NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
	# [center deliverNotification:notification];
}

/*
pub fn text_width(s string) int {
	return 0
}
*/

pub fn bundle_path() string {
	s := ''
	# s = tos2( [[[NSBundle mainBundle] bundlePath] UTF8String]);
	return s
}

[unsafe_fn]
pub fn wait_events() {
	# NSEvent *event = [NSApp nextEventMatchingMask:NSEventMaskAny
	# untilDate:[NSDate distantFuture]
	# inMode:NSDefaultRunLoopMode
	# dequeue:YES];
	# [NSApp sendEvent:event];
}


