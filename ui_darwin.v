// Copyright (c) 2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license
// that can be found in the LICENSE file.
module ui

pub fn message_box(s string) {
	ns_string := nsstring(s)
	# NSAlert *alert = [[NSAlert alloc] init] ;
	# [alert setMessageText:ns_string];
	# [alert runModal];
}

fn nsstring(s string) voidptr {
	# return [ [ NSString alloc ] initWithBytesNoCopy:s.str  length:s.len
	# encoding:NSUTF8StringEncoding freeWhenDone: false];
	return 0
}
