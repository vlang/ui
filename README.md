# V UI 0.0.4

[![Build Status](https://github.com/vlang/ui/workflows/CI/badge.svg)](https://github.com/vlang/ui/commits/master)
[![Sponsor][SponsorBadge]][SponsorUrl]
[![Patreon][PatreonBadge]][PatreonUrl]

[![Twitter handle][]][twitter badge]

<a href='https://github.com/vlang/ui/blob/master/examples/users.v'>
<img src='https://raw.githubusercontent.com/vlang/ui/c2f802a137b5171dade1d5fdc364cd92d34e3ca7/examples/users/screenshot.png' width=712>
</a>


```v
import ui

struct App {
mut:
    window     &ui.Window = unsafe { nil }
    first_name string
    last_name  string
}

fn main() {
    mut app := &App{}
    app.window = ui.window(
        width: 600
        height: 400
        title: 'V UI Demo'
        children: [
            ui.row(
                margin: ui.Margin{10, 10, 10, 10}
                children: [
                    ui.column(
                        width: 200
                        spacing: 13
                        children: [
                            ui.textbox(
                                max_len: 20
                                width: 200
                                placeholder: 'First name'
                                text: &app.first_name
                            ),
                            ui.textbox(
                                max_len: 50
                                width: 200
                                placeholder: 'Last name'
                                text: &app.last_name
                            ),
                        ]
                    ),
                ]
            ),
        ]
    )
    ui.run(app.window)
}
````

### Installation

```bash
v up
v install ui
```

### Running the examples

```bash
cd examples
v run users.v
v run rgb_color.v
v run ...
```

**This is pre-alpha software.**

V UI is a cross-platform UI toolkit written in [the V programming language](https://github.com/vlang/v)
for Windows, macOS, Linux, Android, and soon iOS and the web (JS/WASM). V UI
uses native widgets on Windows and macOS, on all other platforms the widgets
are drawn by V UI. Right now only the non-native widgets are available.

This is a very early version of the library, lots of features are missing, and lots of things will change.

The API is declarative, and there will be hot reloading, similar to SwiftUI and Flutter.

On Linux, V UI will be a full-featured lightweight alternative to GTK and Qt.

[0.1 roadmap](https://github.com/vlang/ui/issues/31)

Discord: [`#v-ui` channel](https://discord.gg/vlang)

Documentation will be available soon. In the meantime use the examples as the documentation. The framework is very simple and straightforward.

### Dependencies

Binaries built with V UI will have no dependencies.

To develop V UI apps, you need to install [V](https://github.com/vlang/v#installing-v-from-source). This takes a couple of seconds.

On some Linux distros you also need a few development dependencies:
- Arch: `sudo pacman -S libxi libxcursor mesa`
- Debian/Ubuntu: `sudo apt install libxi-dev libxcursor-dev mesa-common-dev`
- Fedora: `sudo dnf install libXi-devel libXcursor-devel mesa-libGL-devel`

On ChromeOS Linux/Crostini, install the Debian dependencies listed above followed by this:
- `sudo apt install freeglut3-dev` ([see details](https://github.com/vlang/ui/issues/316))

### License

V UI is licensed under MIT.

### Contributing

Simply open a GitHub pull request.

[twitter handle]: https://img.shields.io/twitter/follow/v_language.svg?style=social&label=Follow
[twitter badge]: https://twitter.com/v_language
[PatreonBadge]: https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fshieldsio-patreon.vercel.app%2Fapi%3Fusername%3Dvlang%26type%3Dpatrons&style=flat
[SponsorBadge]: https://camo.githubusercontent.com/da8bc40db5ed31e4b12660245535b5db67aa03ce/68747470733a2f2f696d672e736869656c64732e696f2f7374617469632f76313f6c6162656c3d53706f6e736f72266d6573736167653d254532253944254134266c6f676f3d476974487562

[PatreonUrl]: https://patreon.com/vlang
[SponsorUrl]: https://github.com/sponsors/medvednikov
