module ui

import os
import sokol.sapp

#include <android/configuration.h>

enum AndroidConfig {
	orientation
	touchscreen
	screensize
	sdkversion
}

fn C.AConfiguration_new() voidptr
fn C.AConfiguration_fromAssetManager(voidptr, voidptr)
fn C.AConfiguration_delete(voidptr)
fn C.AConfiguration_getOrientation(voidptr) u32
fn C.AConfiguration_getTouchscreen(voidptr) u32
fn C.AConfiguration_getScreenSize(voidptr) u32
fn C.AConfiguration_getSdkVersion(voidptr) u32

pub fn android_config(mode AndroidConfig) u32 {
	config := C.AConfiguration_new()
	activity := &os.NativeActivity(sapp.android_get_native_activity())
	C.AConfiguration_fromAssetManager(config, activity.assetManager)
	mut cfg := u32(0)
	match mode {
		.orientation {
			cfg = C.AConfiguration_getOrientation(config)
		}
		.touchscreen {
			cfg = C.AConfiguration_getTouchscreen(config)
		}
		.screensize {
			cfg = C.AConfiguration_getScreenSize(config)
		}
		.sdkversion {
			cfg = C.AConfiguration_getSdkVersion(config)
		}
	}
	C.AConfiguration_delete(config)
	return cfg
}

pub fn message_box(s string) {
	// TODO: Toasted message box
}
