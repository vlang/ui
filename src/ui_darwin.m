// Copyright (c) 2020-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a MIT license
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

void vui_minimize_window(void* window) {
	NSLog(@"MINIMIZE WINDOW");
	[ (__bridge NSWindow *)(window) performMiniaturize:0];
}

void vui_deminimize_window(void* window) {
	NSLog(@"DE-MINIMIZE WINDOW");
	[ (__bridge NSWindow *)(window) deminiaturize:0];
}

void vui_focus_window(void* window) {
	[NSApp activateIgnoringOtherApps:YES];
  [(__bridge NSWindow*)(window) makeKeyAndOrderFront:nil];
}

/*
void vui_take_screenshot(string s) {//void* w, string s) {
	// NSWindow* win=(__bridge NSWindow*)w;
	NSString* path = nsstring(s);

	NSArray<NSDictionary*> *windowInfoList = (__bridge_transfer id)
    CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID);

	NSArray<NSRunningApplication*> *apps =
    [NSRunningApplication runningApplicationsWithBundleIdentifier:
        // Bundle ID of the application, e.g.:  @"com.apple.Safari"];
	if (apps.count == 0) {
		// Application is not currently running
		puts("The application is not running");
		return; // Or whatever
	}
	pid_t appPID = apps[0].processIdentifier;

	NSMutableArray<NSDictionary*> *appWindowsInfoList = [NSMutableArray new];
	for (NSDictionary *info in windowInfoList) {
		if ([info[(__bridge NSString *)kCGWindowOwnerPID] integerValue] == appPID) {
			[appWindowsInfoList addObject:info];
		}
	}

	NSDictionary *appWindowInfo = appWindowsInfoList[0];
	CGWindowID windowID = [appWindowInfo[(__bridge NSString *)kCGWindowNumber] unsignedIntValue];
	NSLog(@"window ID  <%@>", windowID);
	CGImageRef image =
    CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow,
                            windowID, kCGWindowImageBoundsIgnoreFraming|
                            kCGWindowImageNominalResolution);

	CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    if (!destination) {
        NSLog(@"Failed to create CGImageDestination for %@", path);
		return;
    }

    CGImageDestinationAddImage(destination, image, nil);

    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", path);
        CFRelease(destination);
        return;
    }

    CFRelease(destination);
}

void vui_saveImage(NSImage *image, NSString *path) {

   CGImageRef cgRef = [image CGImageForProposedRect:NULL
                                            context:nil
                                              hints:nil];
   NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
   [newRep setSize:[image size]];   // if you want the same resolution
   NSData *pngData = [newRep representationUsingType:NSPNGFileType properties:nil];
   [pngData writeToFile:path atomically:YES];
//    [newRep autorelease];
}

void vui_screenshot(void* w, string s) {
	NSWindow* win=(__bridge NSWindow*)w;
	NSString* path = nsstring(s);
	NSView *view = [win contentView];
	NSImage *image = [[NSImage alloc] initWithData:[[win contentView] dataWithPDFInsideRect:[[win contentView] bounds]]];
	// NSBitmapImageRep *imgRep = [[image representations] objectAtIndex: 0];
	// NSData *imageData = [imgRep representationUsingType: NSPNGFileType properties: nil];
	// NSData *imageData = [image TIFFRepresentation];
	// [imageData writeToFile:fName atomically:NO];
	vui_saveImage(image, path);
} */


