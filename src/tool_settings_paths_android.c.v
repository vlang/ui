module ui

import os
import sokol.sapp

#include <android/configuration.h>

const (
	settings_dir        = os.join_path(get_app_data_directory(), '.vui')
	settings_styles_dir = os.join_path(get_app_data_directory(), '.vui', 'styles')
)

pub fn get_app_data_directory() string {
	activity := &os.NativeActivity(sapp.android_get_native_activity())
	path := unsafe { cstring_to_vstring(activity.internalDataPath) }
	return path
}
