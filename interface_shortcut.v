module ui

// Adding shortcuts field for a Widget or Component (having id field) makes it react as user-dedined shortcuts
// see tool_key for parsing shortcut as string

pub interface Shortcutable {
	id string
mut:
	shortcuts Shortcuts
}

pub fn (mut s Shortcutable) add_shortcut(shortcut string, key_fn ShortcutFn) {
	mods, code, key := parse_shortcut(shortcut)
	if code == 0 {
		s.shortcuts.chars[key] = Shortcut{
			mods: mods
			key_fn: key_fn
		}
	} else {
		s.shortcuts.keys[code] = Shortcut{
			mods: mods
			key_fn: key_fn
		}
	}
}

pub fn (mut s Shortcutable) add_shortcut_context(shortcut string, context voidptr) {
	_, code, key := parse_shortcut(shortcut)
	if code == 0 {
		s.shortcuts.chars[key].context = context
	} else {
		s.shortcuts.keys[code].context = context
	}
}

// This provides user defined shortcut actions (see grid and grid_data as a use case)
pub type ShortcutFn = fn (context voidptr)

pub type KeyShortcuts = map[int]Shortcut
pub type CharShortcuts = map[string]Shortcut

pub struct Shortcuts {
pub mut:
	keys  KeyShortcuts
	chars CharShortcuts
}

pub struct Shortcut {
pub mut:
	mods    KeyMod
	key_fn  ShortcutFn
	context voidptr
}

pub fn char_shortcut(e KeyEvent, shortcuts Shortcuts, context voidptr) {
	// weirdly when .ctrl modifier the codepoint is differently interpreted
	mut s := utf32_to_str(e.codepoint)
	$if macos {
		if e.mods == .ctrl {
			s = rune(96 + e.codepoint).str()
		}
	}
	if s in shortcuts.chars {
		sc := shortcuts.chars[s]
		if has_key_mods(e.mods, sc.mods) {
			if sc.context != voidptr(0) {
				sc.key_fn(sc.context)
			} else {
				sc.key_fn(context)
			}
		}
	}
}

pub fn key_shortcut(e KeyEvent, shortcuts Shortcuts, context voidptr) {
	if int(e.key) in shortcuts.keys {
		sc := shortcuts.keys[int(e.key)]
		if has_key_mods(e.mods, sc.mods) {
			if sc.context != voidptr(0) {
				sc.key_fn(sc.context)
			} else {
				sc.key_fn(context)
			}
		}
	}
}
