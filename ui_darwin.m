// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.

/*
NSString *nsstring(string str) {
  return [[NSString alloc] initWithBytesNoCopy:str.str
                                        length:str.len
                                      encoding:NSUTF8StringEncoding
                                  freeWhenDone:false];
}
*/

void vui_message_box(string s) {
		NSString* ns_string = nsstring(s);
		NSAlert *alert = [[NSAlert alloc] init] ;
		[alert setMessageText:ns_string];
		[alert runModal];
}

void vui_notify(string title, string msg) {
	NSString* ns_msg = nsstring(msg);
	NSString* ns_title = nsstring(title);
	NSUserNotification *notification = [[NSUserNotification alloc] init]; // retain];
	notification.title = ns_title;
	notification.informativeText = ns_msg;
	NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
		[center deliverNotification:notification];
}

void vui_wait_events() {
	NSEvent *event = [NSApp nextEventMatchingMask:NSEventMaskAny
		untilDate:[NSDate distantFuture]
		inMode:NSDefaultRunLoopMode	dequeue:YES];
	[NSApp sendEvent:event];
}

string vui_bundle_path() {
	return tos2([[[NSBundle mainBundle] bundlePath] UTF8String]);
}


