# V UI 0.0.1

[![Build Status](https://github.com/vlang/ui/workflows/CI/badge.svg)](https://github.com/vlang/ui/commits/master)
<a href='https://patreon.com/vlang'><img src='https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fshieldsio-patreon.herokuapp.com%2Fvlang%2Fpledges&style=for-the-badge' height='20'></a>
[![Twitter handle][]][Twitter badge]

<a href='https://github.com/vlang/ui/blob/master/examples/users/users.v'>
<img src='https://raw.githubusercontent.com/vlang/ui/c2f802a137b5171dade1d5fdc364cd92d34e3ca7/examples/users/screenshot.png' width=712>
</a>

### Installation
```bash
v install ui
```

### Running the examples
```bash
v run ~/.vmodules/ui/examples/users/users.v

```

**This is pre-alpha software.**

V UI is a cross-platform UI toolkit written in [the V programming language](https://github.com/vlang/v)
for Windows, macOS, Linux, and soon Android, iOS and the web (JS/WASM). V UI
uses native widgets on Windows and macOS, on all other platforms the widgets
are drawn by V UI.  Right now only the non-native widgets are available.

This is a very early version of the library, lots of features are missing
(layouts, certain widgets, etc), lots of things will change.

There will be a declarative version of the API, similar to SwiftUI.

V UI is licensed under GPL3. A commercial license will be available.
Open-source projects will have access to the commercial license for free. Every
single feature will be open-sourced right away and available under both
licenses. At some point in the future the library will be relicensed under MIT.

Discord: https://discord.gg/n7c74HM (`#v-ui` channel)


### Dependencies

Binaries built with V UI will have no dependencies.

To develop V UI apps, you need to install [V](https://github.com/vlang/v#installing-v-from-source),
`glfw` and `freetype`. `glfw` dependency will soon be removed.

```
macOS:
brew install glfw freetype

Debian/Ubuntu:
sudo apt install libglfw3 libglfw3-dev libfreetype6-dev

Arch/Manjaro:
sudo pacman -S glfw-x11 freetype2

Fedora:
sudo dnf install glfw glfw-devel freetype-devel

Windows:
git clone --depth=1 https://github.com/ubawurinna/freetype-windows-binaries [path to v repo]/thirdparty/freetype/
```

[Twitter handle]: https://img.shields.io/twitter/follow/v_language.svg?style=social&label=Follow
[Twitter badge]: https://twitter.com/intent/follow?screen_name=v_language
