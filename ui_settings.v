module ui

import os
import json
import gx

const (
	settings_path = os.join_path(os.getenv('HOME'), '.vui', 'settings.json')
)

// Structure to save UI configuration
struct SettingsUI {
pub mut:
	// Atomic
	int_    map[string]int
	f32_    map[string]f32
	bool_   map[string]bool
	string_ map[string]string
	color_  map[string]gx.Color
	// Arrays
	ints_    map[string][]int
	f32s_    map[string][]f32
	bools_   map[string][]bool
	strings_ map[string][]string
	colors_  map[string][]gx.Color
}

fn (c &SettingsUI) int(k ...string) int {
	return c.int_[k.join('.')]
}

fn (mut c SettingsUI) int_for(val int, k ...string) {
	c.int_[k.join('.')] = val
}

fn (c &SettingsUI) ints(k ...string) []int {
	return c.ints_[k.join('.')]
}

fn (mut c SettingsUI) ints_for(val []int, k ...string) {
	c.ints_[k.join('.')] = val
}

fn (c &SettingsUI) f32(k ...string) f32 {
	return c.f32_[k.join('.')]
}

fn (c &SettingsUI) f32s(k ...string) []f32 {
	return c.f32s_[k.join('.')]
}

fn (mut c SettingsUI) f32_for(val f32, k ...string) {
	c.f32_[k.join('.')] = val
}

fn (mut c SettingsUI) f32s_for(val []f32, k ...string) {
	c.f32s_[k.join('.')] = val
}

fn (c &SettingsUI) bool(k ...string) bool {
	return c.bool_[k.join('.')]
}

fn (mut c SettingsUI) bool_for(val bool, k ...string) {
	c.bool_[k.join('.')] = val
}

fn (c &SettingsUI) bools(k ...string) []bool {
	return c.bools_[k.join('.')]
}

fn (mut c SettingsUI) bools_for(val []bool, k ...string) {
	c.bools_[k.join('.')] = val
}

fn (c &SettingsUI) string(k ...string) string {
	return c.string_[k.join('.')]
}

fn (mut c SettingsUI) string_for(val string, k ...string) {
	c.string_[k.join('.')] = val
}

fn (c &SettingsUI) strings(k ...string) []string {
	return c.strings_[k.join('.')]
}

fn (mut c SettingsUI) strings_for(val []string, k ...string) {
	c.strings_[k.join('.')] = val
}

fn (c &SettingsUI) color(k ...string) gx.Color {
	return c.color_[k.join('.')]
}

fn (mut c SettingsUI) color_for(val gx.Color, k ...string) {
	c.color_[k.join('.')] = val
}

fn (c &SettingsUI) colors(k ...string) []gx.Color {
	return c.colors_[k.join('.')]
}

fn (mut c SettingsUI) colors_for(val []gx.Color, k ...string) {
	c.colors_[k.join('.')] = val
}

fn load_settings(path string) ?SettingsUI {
	raw := os.read_file(path) ?
	settings := json.decode(SettingsUI, raw) ?
	return settings
}

fn save_settings(path string, s SettingsUI) ? {
	settings := json.encode_pretty(s)
	os.write_file(path, settings) ?
}

pub fn (mut w Window) load_settings() {
	if !os.exists(ui.settings_path) {
		w.save_settings()
	}
	w.settings = load_settings(ui.settings_path) or { panic(err) }
}

pub fn (mut w Window) save_settings() {
	if !os.exists(ui.settings_path) {
		os.mkdir_all(os.dir(ui.settings_path)) or { panic(err) }
	}
	save_settings(ui.settings_path, w.settings) or { panic(err) }
}

/*
styles, font
*/
