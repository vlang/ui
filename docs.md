# V UI Library Documentation

## Introduction

V UI is a cross-platform UI toolkit for the V programming language. It provides a set of widgets, layouts, and components to build graphical user interfaces. This documentation provides an overview of the library based on its source code and examples.

## Core Concepts

### Window

-   Every UI application starts with a `ui.window`.
-   The `ui.run(window)` function starts the main event loop.

```v
import ui

fn main() {
    // Create the main window
    window := ui.window(
        width: 800,
        height: 600,
        title: 'My App',
        layout: ui.column( // Add your root layout here
            children: [
                ui.label(text: 'Hello, V UI!')
            ]
        )
    )
    // Start the event loop
    ui.run(window)
}
```

### Layouts

V UI uses layouts to arrange widgets. The primary layouts are:

-   `ui.row`: Arranges children horizontally.
-   `ui.column`: Arranges children vertically.
-   `ui.box_layout`: Arranges children based on absolute or relative coordinates and sizes within the box.
-   `ui.canvas_layout`: Allows placing widgets at absolute positions (using `ui.at(x, y, widget)`) and custom drawing.

Layouts manage the size and position of their children based on parameters like `widths`, `heights`, `spacing`, `margin_`, `alignment`, etc.

### Widgets

Widgets are the basic building blocks of the UI (Buttons, TextBoxes, Labels, etc.). They are typically created using functions like `ui.button(...)`, `ui.textbox(...)`, etc.

### Components (`ui.component` or `uic`)

Components are higher-level UI elements built using core widgets and layouts. They often encapsulate state and behavior (e.g., `uic.filebrowser_stack`, `uic.colorpalette_stack`). They usually follow a pattern:

1.  A factory function creates the component's root layout (e.g., `uic.accordion_stack`).
2.  A companion function retrieves the component's state struct from its layout (e.g., `uic.accordion_component`).
3.  Component state structs often hold references to their internal widgets.

## Core Widgets

### `ui.button`

Displays a clickable button.

**Key Parameters (`ButtonParams`):**

-   `id`: (string) Unique identifier.
-   `text`: (string) Text displayed on the button.
-   `on_click`: (fn(&Button)) Callback function executed when the button is clicked.
-   `width`, `height`: (int) Fixed size in pixels.
-   `radius`: (f64) Corner radius (0.0 for sharp corners, > 0 for rounded).
-   `tooltip`: (string) Text to display on hover.
-   `tooltip_side`: (ui.Side) Where the tooltip appears relative to the button.
-   `bg_color`: (&gx.Color) Background color.
-   `theme`: (string) Apply a predefined theme style.

**Example (`users.v`):**

```v
ui.button(
    width:    60,
    text:     'Add user',
    tooltip:  'Required fields:\n  * First name\n  * Last name\n  * Age',
    on_click: app.btn_add_click, // `app` holds the application state
    radius:   .0
),
```

### `ui.textbox`

Allows users to input or display text.

**Key Parameters (`TextBoxParams`):**

-   `id`: (string) Unique identifier.
-   `text`: (&string) Pointer to a string variable for two-way data binding.
-   `placeholder`: (string) Text displayed when the textbox is empty.
-   `width`, `height`: (int) Size in pixels.
-   `mode`: (TextBoxMode) Flags like `.multiline`, `.read_only`, `.word_wrap`.
-   `max_len`: (int) Maximum number of characters allowed.
-   `is_numeric`: (bool) Restrict input to numbers.
-   `is_password`: (bool) Mask input characters.
-   `read_only`: (bool) Prevent user input.
-   `on_change`: (fn(&TextBox)) Callback when text changes.
-   `on_enter`: (fn(&TextBox)) Callback when Enter key is pressed.
-   `scrollview`: (bool) Enable scrolling for multiline textboxes.
-   `bg_color`: (gx.Color) Background color.
-   `text_size`: (f64) Font size.
-   `text_font_name`: (string) Font to use.

**Example (`users.v`):**

```v
// Simple textbox with placeholder and data binding
ui.textbox(
    max_len:     20,
    width:       200,
    placeholder: 'First name',
    text:        &app.first_name, // Bind to app.first_name string
    is_error:    &app.is_error,  // Bind error state
    is_focused: true
),

// Multiline textbox
ui.textbox(
    mode:               .multiline,
    id:                 'edit',
    z_index:            20,
    height:             200,
    line_height_factor: 1.0,
    text_size:          24,
    text_font_name:     'fixed',
    bg_color:           gx.hex(0xfcf4e4ff)
)
```

### `ui.label`

Displays static text.

**Key Parameters (`LabelParams`):**

-   `id`: (string) Unique identifier.
-   `text`: (string) The text to display.
-   `width`, `height`: (int) Size in pixels.
-   `justify`: ([]f64) Alignment within its bounds (e.g., `ui.center_center`, `ui.top_left`).
-   `text_size`: (f64) Font size.
-   `text_color`: (gx.Color) Text color.
-   `clipping`: (bool) Clip text if it exceeds bounds.

**Example (`users.v`):**

```v
ui.label(id: 'counter', text: '2/10', text_font_name: 'fixed_bold_italic')
```

### `ui.checkbox`

A standard checkbox with a label.

**Key Parameters (`CheckBoxParams`):**

-   `id`: (string) Unique identifier.
-   `text`: (string) Label text next to the checkbox.
-   `checked`: (bool) Initial checked state.
-   `on_click`: (fn(&CheckBox)) Callback when clicked.
-   `disabled`: (bool) Disable interaction.

**Example (`users.v`):**

```v
ui.checkbox(
    checked: true,
    text:    'Online registration'
),
ui.checkbox(text: 'Subscribe to the newsletter')
```

### `ui.radio`

Allows selecting one option from a group.

**Key Parameters (`RadioParams`):**

-   `id`: (string) Unique identifier.
-   `values`: ([]string) List of options to display.
-   `title`: (string) Optional title displayed above the radio buttons.
-   `width`: (int) Width of the control (behavior depends on `horizontal` and `compact`).
-   `horizontal`: (bool) Arrange options horizontally instead of vertically.
-   `compact`: (bool) Try to fit options within the specified width (used with `horizontal`).
-   `on_click`: (fn(&Radio)) Callback when an option is selected.

**Methods:**

-   `selected_value()`: Returns the string value of the currently selected option.

**Example (`users.v`):**

```v
app.country = ui.radio(
    width:  200,
    values: ['United States', 'Canada', 'United Kingdom', 'Australia'],
    title:  'Country'
)
// Get selected value later:
selected := app.country.selected_value()
```

### `ui.slider`

A slider control for selecting a value within a range.

**Key Parameters (`SliderParams`):**

-   `id`: (string) Unique identifier.
-   `orientation`: (ui.Orientation) `.horizontal` or `.vertical`.
-   `min`, `max`: (int) Minimum and maximum values.
-   `val`: (f32) Current value.
-   `on_value_changed`: (fn(&Slider)) Callback when the value changes.
-   `width`, `height`: (int) Size of the slider track.
-   `thumb_color`: (gx.Color) Color of the slider handle.

**Example (`examples/slider.v`):**

```v
app.hor_slider = ui.slider(
    width:            200,
    height:           20,
    orientation:      .horizontal,
    max:              100,
    val:              0,
    on_value_changed: app.on_hor_value_changed
)
```

### `ui.progressbar`

Displays progress visually.

**Key Parameters (`ProgressBarParams`):**

-   `id`: (string) Unique identifier.
-   `width`, `height`: (int) Size in pixels.
-   `min`, `max`: (int) Minimum and maximum progress values.
-   `val`: (int) Current progress value.
-   `color`: (gx.Color) Color of the progress fill.
-   `bg_color`: (gx.Color) Background color of the track.

**Example (`users.v`):**

```v
app.pbar = ui.progressbar(
    width: 170,
    max:   10,
    val:   2 // Initial value, can be updated later: app.pbar.val++
)
```

### `ui.rectangle`

Draws a simple rectangle, optionally with text and rounded corners.

**Key Parameters (`RectangleParams`):**

-   `id`: (string) Unique identifier.
-   `width`, `height`: (int) Size in pixels.
-   `color`: (gx.Color) Fill color.
-   `border`: (bool) Draw a border.
-   `border_color`: (gx.Color) Color of the border.
-   `radius`: (int) Corner radius for rounded rectangle.
-   `text`: (string) Text to display inside the rectangle.

**Example (`examples/rectangles.v`):**

```v
ui.rectangle(
    height: 64,
    width:  64,
    color:  gx.rgb(255, 100, 100),
    radius: 10,
    text:   'Red'
)
```

### `ui.picture`

Displays an image from a file.

**Key Parameters (`PictureParams`):**

-   `id`: (string) Unique identifier.
-   `path`: (string) Path to the image file.
-   `width`, `height`: (int) Display size (image will be scaled).
-   `movable`: (bool) Allow dragging the picture (usually with Shift key).
-   `tooltip`: (string) Tooltip text.

**Example (`users.v`):**

```v
ui.picture(
    id:     'logo',
    width:  50,
    height: 50,
    path:   logo // Variable holding the image path
)
```

### `ui.canvas` / `ui.canvas_plus`

A drawing surface for custom graphics using `gg` drawing functions. `canvas_plus` adds background color/radius and other features.

**Key Parameters (`CanvasParams`, `CanvasLayoutParams`):**

-   `id`: (string) Unique identifier.
-   `width`, `height`: (int) Size of the canvas.
-   `draw_fn` / `on_draw`: (fn(&gg.Context, &Canvas) or fn(mut DrawDevice, &CanvasLayout)) Callback function for drawing. The `DrawDevice` version is more flexible for different rendering backends.
-   `on_click`, `on_mouse_move`, etc.: Event callbacks.
-   `bg_color`, `bg_radius`: (For `canvas_plus`) Background styling.
-   `scrollview`: (bool) Enable scrolling if content exceeds bounds.

**Example (`users.v` using `canvas_plus`):**

```v
ui.canvas_plus(
    width:     400,
    height:    275,
    on_draw:   app.draw, // Custom drawing function in the App struct
    bg_color:  gx.Color{255, 220, 220, 150},
    bg_radius: 10
)

// Inside the app.draw function:
fn (app &State) draw(mut d ui.DrawDevice, c &ui.CanvasLayout) {
    // Use methods like c.draw_device_rect_empty, c.draw_device_line, c.draw_device_text
    // Example:
    c.draw_device_rect_empty(d, marginx, y, table_width, cell_height, gx.gray)
    c.draw_device_text(d, marginx + 5, y + 5, user.first_name)
    // ...
}
```

### `ui.listbox`

Displays a list of selectable items.

**Key Parameters (`ListBoxParams`):**

-   `id`: (string) Unique identifier.
-   `width`, `height`: (int) Size of the listbox.
-   `items`: (map[string]string) Map of item ID to display text.
-   `on_change`: (fn(&ListBox)) Callback when selection changes.
-   `multi`: (bool) Allow multiple selections.
-   `ordered`: (bool) Allow reordering items via drag-and-drop.
-   `scrollview`: (bool) Enable scrolling.
-   `files_dropped`: (bool) Accept dropped files (adds them to the list).

**Methods:**

-   `selected()`: Returns `!(id, text)` of the selected item.
-   `selected_item()`: Returns `(id, text)` or `('', '')` if none selected.
-   `add_item(id, text)`, `delete_item(id)`, `reset()`.

**Example (`examples/crud.v`):**

```v
ui.listbox(
    id: 'lb_people'
    // Items added dynamically via app.update_listbox()
),

// Update items later:
app.lb_people.reset()
for p in app.people {
    app.lb_people.add_item(p.id, person_name(p.name, p.surname))
}

// Get selection:
id, _ := app.lb_people.selected_item()
```

### `ui.dropdown`

A dropdown menu for selecting one option.

**Key Parameters (`DropdownParams`):**

-   `id`: (string) Unique identifier.
-   `width`, `height`: (int) Size of the collapsed dropdown.
-   `items`: ([]DropdownItem) List of items (`DropdownItem{text: '...'}`).
-   `texts`: ([]string) Alternative way to specify items using just text.
-   `def_text`: (string) Text displayed when no item is selected.
-   `selected_index`: (int) Index of the initially selected item (-1 for none).
-   `on_selection_changed`: (fn(&Dropdown)) Callback when selection changes.

**Methods:**

-   `selected()`: Returns the selected `DropdownItem`.

**Example (`examples/7guis/flightbooker.v`):**

```v
ui.dropdown(
    id:                   'dd_flight',
    z_index:              10,
    selected_index:       0,
    on_selection_changed: app.dd_change,
    items:                [
        ui.DropdownItem{ text: 'one-way flight' },
        ui.DropdownItem{ text: 'return flight' },
    ]
),
```

### `ui.menu` / `ui.menuitem` / `ui.menubar`

Create context menus or menu bars.

**Key Parameters:**

-   `ui.menuitem`:
    -   `text`: (string) Display text.
    -   `action`: (fn(&MenuItem)) Callback when clicked (for non-submenu items).
    *   `submenu`: (&Menu) A nested menu.
-   `ui.menu`:
    -   `id`: (string) Identifier.
    *   `text`: (string) Text for the menu button itself (if not part of a menubar).
    *   `items`: ([]&MenuItem) List of menu items.
-   `ui.menubar`:
    *   `id`: (string) Identifier.
    *   `items`: ([]&MenuItem) List of top-level menu items (often containing submenus).

**Example (`examples/nested_clipping.v` - MenuBar structure):**
(See `examples/resizable_menu_window.v` for a full MenuBar example)

```v
// Structure definition
menu_items := [
    ui.menuitem(
        text:    'File',
        submenu: ui.menu(
            items: [
                ui.menuitem(text: 'Open', action: menu_click),
                ui.menuitem(text: 'Save', action: menu_click),
                ui.menuitem(text: 'Exit', action: menu_click),
            ]
        )
    ),
    // ... other top-level menus
]
// Usage in layout
ui.menubar(
    id:    'menubar',
    items: menu_items
)
```

### `ui.grid` (Simple)

Displays data in a simple, non-interactive grid. (Note: This seems less used/developed than the `GridComponent`).

**Key Parameters (`GridParams`):**

-   `header`: ([]string) Column headers.
-   `body`: ([][]string) 2D array of cell data.
-   `width`, `height`: (int) Size.

**Example (`examples/grid.v`):**

```v
h := ['One', 'Two', 'Three']
b := [['body one', 'body two', 'body three'], ['V', 'UI is', 'Beautiful']]
app.grid = ui.grid(header: h, body: b, width: win_width - 10, height: win_height)
```

### `ui.transition`

Manages animated transitions for integer properties (like widget position offsets).

**Key Parameters (`TransitionParams`):**

-   `duration`: (int) Transition duration in milliseconds.
-   `easing`: (EasingFunction) Function defining the transition curve (e.g., `ui.easing(.ease_in_out_cubic)`).
-   `animated_value`: (&int) Pointer to the integer value to animate.

**Methods:**

-   `set_value(&int)`: Sets the target variable to animate.
-   `target_value = X`: Sets the destination value for the animation.

**Example (`examples/transitions.v`):**

```v
// Initialization
app.x_transition = ui.transition(duration: 750, easing: ui.easing(.ease_in_out_cubic))
app.y_transition = ui.transition(duration: 750, easing: ui.easing(.ease_in_out_quart))
app.picture = ui.picture(...)

// In window layout:
children: [
    // ... other widgets
    app.picture,
    app.x_transition, // Add transition widgets to the window
    app.y_transition,
]

// To start animation:
fn (mut app App) btn_toggle_click(button &ui.Button) {
    // Set the target variable ONCE
    if app.x_transition.animated_value == 0 {
        app.x_transition.set_value(&app.picture.offset_x)
        app.y_transition.set_value(&app.picture.offset_y)
    }
    // Set the destination value
    app.x_transition.target_value = new_x_position
    app.y_transition.target_value = new_y_position
    // The draw() method of the transition handles the animation
}
```

### `ui.switch`

A toggle switch control.

**Key Parameters (`SwitchParams`):**

-   `id`: (string) Unique identifier.
-   `open`: (bool) Initial state (true for on/open).
-   `on_click`: (fn(&Switch)) Callback when toggled.

**Example (`examples/switch.v`):**

```v
app.switcher = ui.switcher(open: true, on_click: app.on_switch_click)
```

## Layouts

### `ui.row` / `ui.column`

These are implemented using `ui.stack` internally. They arrange children linearly.

**Key Parameters (`RowParams`, `ColumnParams`):**

-   `id`: (string) Identifier.
-   `children`: ([]Widget) The widgets to arrange.
-   `widths`, `heights`: (ui.Size - []f64 or f64) Defines how children share space along the main axis (row uses `widths`, column uses `heights`) and how they size on the cross axis.
    -   `ui.stretch`: Child takes a proportional amount of the remaining space (default weight 1.0). `2 * ui.stretch` gives double weight.
    -   `ui.compact`: Child takes its natural/minimum size.
    -   `> 1`: Fixed size in pixels.
    -   `0 < size <= 1`: Proportional size relative to the parent stack's dimension in that axis.
-   `spacing`: (f64) Space between children (pixels if >=1, relative if <1).
-   `margin_`: (f64) Uniform margin around the stack (pixels if >=1, relative if <1).
-   `margin`: (ui.Margin) Specific margins for top, right, bottom, left.
-   `alignment`: (VerticalAlignment/HorizontalAlignment) Default alignment for children on the cross axis.
-   `alignments`: (VerticalAlignments/HorizontalAlignments) Fine-grained alignment control for specific children by index.
-   `bg_color`: (gx.Color) Background color for the stack area.
-   `scrollview`: (bool) Enable scrolling if content exceeds bounds.

**Example (`users.v`):**

```v
// Row with compact buttons and spacing
ui.row(
    id:       'btn_row',
    widths:   ui.compact, // Children take their own width
    heights:  20.0,       // Fixed height for the row
    spacing:  80,         // 80px spacing between buttons
    children: [ /* ... buttons ... */ ]
)

// Column with mixed height children
ui.column(
    spacing:    10,
    widths:     ui.compact, // Column takes width of widest child
    heights:    ui.compact, // Children take their own height
    scrollview: true,      // Enable vertical scrolling if needed
    children:   [ /* ... textboxes, checkboxes, etc. ... */ ]
)
```

### `ui.box_layout`

Provides absolute and relative positioning and sizing within a parent container. Very flexible but requires careful definition.

**Key Parameters (`BoxLayoutParams`):**

-   `id`: (string) Identifier.
-   `children`: (map[string]Widget) A map where the key defines the child's `id` and `bounding box`, and the value is the `Widget`.
-   `scrollview`: (bool) Enable scrolling.

**Bounding Box Syntax (in map key):** `child_id: bounding_spec`

-   `child_id`: An identifier for the child *within this box layout*.
-   `bounding_spec`: Defines position and size.
    -   `(x, y)`: Coordinates (top-left).
    -   `(w, h)`: Size.
    -   Coordinates/Sizes can be:
        -   Pixels (e.g., `10`, `-5` for offset from bottom/right).
        -   Percentage (e.g., `50%`).
        -   Relative to another child (e.g., `@other_id.x + 5`, `@other_id.w`). Uses `ui.calculate` internally.
    -   Operators:
        -   `(x, y) -> (x2, y2)`: Define by top-left and bottom-right corners.
        -   `(x, y) ++ (w, h)`: Define by top-left corner and size.
    -   Special Values:
        -   `stretch`: Equivalent to `(0, 0) -> (100%, 100%)`.
        -   `hidden`: Makes the child invisible and excluded from layout.

**Example (`examples/layout/box_layout.v`):**

```v
ui.box_layout(
    id:       'bl',
    children: {
        // Top-left corner, 30x30 pixels
        'id1: (0,0) ++ (30,30)': ui.rectangle(...),
        // From (30,30) to 30.5 pixels from the right/bottom edges
        'id2: (30,30) -> (-30.5,-30.5)': ui.rectangle(...),
        // From center (50%, 50%) to bottom-right corner (100%, 100%)
        'id3: (50%,50%) ->  (100%,100%)': ui.rectangle(...),
        // Bottom-right corner, 30x30 pixels (size defined from bottom-right)
        'id4: (-30.5, -30.5) ++ (30,30)': ui.rectangle(...),
        // Position relative to id4, size 20x20
        'id5: (@id4.x + 5, @id4.y+5) ++ (20,20)': ui.rectangle(...)
    }
)
```

### `ui.canvas_layout`

Similar to `box_layout` but uses `ui.at(x, y, widget)` placed directly in its `children` array instead of a map. Also allows custom drawing via `on_draw`.

**Key Parameters (`CanvasLayoutParams`):**

-   `id`: (string) Identifier.
-   `children`: ([]Widget) List of widgets, often wrapped in `ui.at()`.
-   `on_draw`: (fn(mut DrawDevice, &CanvasLayout)) Custom drawing callback.
-   `scrollview`: (bool) Enable scrolling.
-   `full_width`, `full_height`: (int) Define the total scrollable area size if different from content bounds.

**Example (`examples/layout/canvas_layout.v`):**

```v
ui.canvas_layout(
    id:              'demo_cl',
    on_draw:         draw, // Custom background drawing
    scrollview:      true,
    children:        [
        ui.at(10, 10, ui.button(id:'b_thm', ...)), // Place button at (10, 10)
        ui.at(120, 10, ui.dropdown(...)),         // Place dropdown at (120, 10)
        // ... other widgets placed with ui.at()
    ]
)
```

## Components (`uic`)

These provide more complex, pre-built functionalities.

### `uic.accordion_stack`

Creates collapsible sections.

-   `id`: (string) Base ID.
-   `titles`: ([]string) Titles for each section header.
-   `children`: ([]ui.Widget) Content for each section.
-   `scrollview`: (bool) Enable scrolling for the entire accordion.

### `uic.alpha_stack`

A slider and textbox combination for selecting an alpha (transparency) value (0-255).

-   `id`: (string) Base ID.
-   `alpha`: (int) Initial alpha value.
-   `on_changed`: (fn(&AlphaComponent)) Callback on value change.

### `uic.colorbox_stack` / `uic.colorbox_subwindow_add`

A color picker component with Hue, Saturation/Value, and RGB inputs. Often used within a subwindow added via `uic.colorbox_subwindow_add`.

-   `id`: (string) Base ID.
-   `light`, `hsl`, `drag`: (bool) Configuration options.
-   `connect(&gx.Color)`: Links the picker to a color variable.
-   `connect_colorbutton(&ColorButtonComponent)`: Links to a `uic.colorbutton`.

### `uic.colorbutton`

A button that displays a color and can open a `colorbox` subwindow on right-click.

-   `id`: (string) ID.
-   `bg_color`: (&gx.Color) Pointer to the color variable it represents.
-   `on_click`: (fn(&ColorButtonComponent)) Left-click callback.
-   `on_changed`: (fn(&ColorButtonComponent)) Callback when its color is changed (e.g., by the connected colorbox).

### `uic.colorpalette_stack`

Displays a palette of colors, including a main editable color and several swatches, plus an alpha slider.

-   `id`: (string) Base ID.
-   `ncolors`: (int) Number of palette swatches.
-   `connect_color(&gx.Color)`: Links the palette's *output* color to a variable.

### `uic.colorsliders_stack`

Provides separate R, G, B sliders and textboxes.

-   `id`: (string) Base ID.
-   `color`: (gx.Color) Initial color.
-   `orientation`: (ui.Orientation) `.horizontal` or `.vertical`.
-   `on_changed`: (fn(&ColorSlidersComponent)) Callback on value change.
-   `color()`: Method to get the current `gx.Color`.
-   `set_color(gx.Color)`: Method to set the sliders' color.

### `uic.doublelistbox_stack`

Two listboxes with buttons (>>, <<, clear) to move items between them.

-   `id`: (string) Base ID.
-   `items`: ([]string) Initial items for the left listbox.
-   `values()`: Method to get the items currently in the *right* listbox.

### `uic.filebrowser_stack` / `uic.filebrowser_subwindow_add`

A file/directory browser using a tree view. Often used within a subwindow.

-   `id`: (string) Base ID.
-   `dirs`: ([]string) Initial directories to display.
-   `folder_only`: (bool) Only allow selection of folders.
-   `on_click_ok`: (fn(&Button)) Callback for the 'Ok' button.
-   `on_click_cancel`: (fn(&Button)) Callback for the 'Cancel' button.
-   `selected_full_title()`: Method to get the full path of the selected item.

### `uic.fontbutton` / `uic.fontchooser_stack` / `uic.fontchooser_subwindow_add`

`fontbutton` opens a `fontchooser` subwindow to select a font for a target widget (specified by `dtw: &ui.DrawTextWidget`).

-   `fontbutton`:
    -   `id`: (string) ID.
    -   `dtw`: (&ui.DrawTextWidget) The widget whose font will be changed.
-   `fontchooser_subwindow_add`: Adds the necessary subwindow to the main window.

### `uic.gg_canvaslayout`

Integrates a `gg` application (implementing `ui.GGApplication`) into a V UI layout. Used in `examples/component/gg2048.v`.

-   `id`: (string) ID.
-   `app`: (ui.GGApplication) The `gg` application instance.

### `uic.grid_canvaslayout` / `uic.datagrid_stack` / `uic.gridsettings_stack`

A powerful, interactive data grid component built on `canvas_layout`. `datagrid_stack` combines the grid with hideable settings.

-   `GridParams`:
    -   `id`: (string) Base ID.
    -   `vars`: (map[string]GridData) Data columns. `GridData` can be `[]string`, `[]bool`, `[]int`, `[]f64`, or `uic.Factor { levels [], values [] }`.
    -   `formulas`: (map[string]string) Spreadsheet-like formulas (e.g., `'B1': '=sum(C1:C5)'`).
    -   `width`, `height`: (int) Default cell size.
-   `DataGridParams` wraps `GridParams` and adds settings options.
-   `GridSettingsComponent`: Provides UI for sorting columns.

### `uic.hideable_stack`

Wraps another layout, allowing it to be shown or hidden, often via a shortcut.

-   `id`: (string) Base ID.
-   `layout`: (&ui.Stack) The layout to hide/show.
-   `hidden`: (bool) Initial state.
-   `hideable_toggle(window, id)`, `hideable_show(window, id)`, `hideable_hide(window, id)`.
-   `hideable_add_shortcut(...)`.

### `uic.menufile_stack`

A common pattern for file menus: includes New, Open, Save buttons and a directory tree view (`dirtreeview_stack`). Used in `editor.v`.

-   `id`: (string) Base ID.
-   `dirs`: ([]string) Initial directories.
-   `on_file_changed`: (fn(&MenuFileComponent)) Callback when a file is selected in the tree.
-   `on_new`: (fn(&MenuFileComponent)) Callback for 'New' button action.
-   `on_save`: (fn(&MenuFileComponent)) Callback for 'Save' button action.

### `uic.messagebox_stack` / `uic.messagebox_subwindow_add`

Displays a simple message box with text and an OK button, usually within a subwindow.

-   `id`: (string) ID for the subwindow.
-   `text`: (string) Message to display.
-   `width`, `height`: (int) Size of the message box.

### `uic.rasterview_canvaslayout`

Displays and allows basic pixel editing of images. Used in `vui_png.v`. Often combined with `uic.colorpalette_stack`.

-   `id`: (string) Base ID.
-   `on_click`: (fn(&RasterViewComponent)) Callback on pixel click.
-   `load_image(path)`, `save_image_as(path)`, `new_image()`.
-   `set_pixel(i, j, color)`, `get_pixel(i, j)`.

### `uic.setting_font`

A row component (likely used in settings dialogs) combining labels and a `uic.fontbutton`. Used in `vui_settings.v`.

-   `id`: (string) Base ID.
-   `text`: (string) Label for the setting.

### `uic.splitpanel_stack`

Creates two resizable panels separated by a draggable splitter bar.

-   `id`: (string) Base ID.
-   `child1`, `child2`: (&ui.Widget) The widgets for the two panels.
-   `direction`: (ui.Direction) `.row` (vertical splitter) or `.column` (horizontal splitter).
-   `weight`: (f64) Initial percentage (0-100) of space allocated to `child1`.

### `uic.tabs_stack`

Creates a tabbed interface.

-   `id`: (string) Base ID.
-   `tabs`: ([]string) List of tab titles.
-   `pages`: ([]ui.Widget) List of widgets corresponding to each tab's content.
-   `active`: (int) Index of the initially active tab.

### `uic.treeview_stack` / `uic.dirtreeview_stack`

Displays hierarchical data. `dirtreeview_stack` is specialized for directory structures.

-   `id`: (string) Base ID.
-   `trees`: ([]uic.Tree or []string for `dirtreeview`) The hierarchical data. `uic.Tree` has `title` and `items []TreeItem` (which can be string or another Tree).
-   `on_click`: (fn(&ui.CanvasLayout, mut uic.TreeViewComponent)) Callback when an item is clicked.
-   `selected_full_title()`: Method to get the path-like title of the selected item.
-   `incr_mode`: (bool) Load subdirectories incrementally on expansion (for `dirtreeview`).
-   `hidden_files`: (bool) Show hidden files/dirs (for `dirtreeview`).

## Application Structure (`ui.Application`)

Many examples (`apps/editor`, `apps/users`, etc.) use a common structure:

1.  Define an `AppUI` (or similar) struct marked `@[heap]`. This holds application state, including references to important widgets (`&ui.Window`, `&ui.Layout`, specific buttons/textboxes).
2.  Define an `AppUIParams` struct marked `@[params]` for initialization parameters.
3.  Implement a `new(params)` function to create and initialize the `AppUI` instance, including calling `make_layout()`.
4.  Implement an `app(params)` function that returns `&ui.Application(&AppUI)`.
5.  Implement a `make_layout()` method on `AppUI` that constructs the UI using `ui.row`, `ui.column`, widgets, and components, assigning the result to `app.layout`.
6.  Optionally implement an `on_init` callback (`fn [mut app] (w &ui.Window)`) assigned to `app.on_init` for setup after the window is created (e.g., adding shortcuts).

This pattern encapsulates the UI's state and construction logic.

## Examples

The library includes several examples demonstrating various features:

-   **`apps/editor`**: A basic text editor using `menufile_stack`, `hideable_stack`, and `textbox`.
-   **`apps/users`**: Demonstrates forms, data binding, `canvas_plus` for custom drawing (a table).
-   **`apps/v2048`**: Shows integration with `gg` graphics library using `gg_canvaslayout`.
-   **`examples/7guis`**: Implementations of the 7 GUIs tasks (Counter, Temperature Converter, Flight Booker, Timer, CRUD, Circle Drawer, Cells) showcasing different widgets and state management.
-   **`examples/component`**: Examples focused on specific components (`accordion`, `colorbox`, `grid`, `splitpanel`, `tabs`, `treeview`, etc.).
-   **`examples/layout`**: Examples focusing on different layout managers (`box_layout`, `canvas_layout`, `row`, `column`).
-   **`examples/` (Others)**: Various examples like `calculator`, `webview`, `transitions`, `nested_scrollview`, `demo_textbox`, etc.
-   **`bin/`**: Contains runnable applications:
    -   `vui_demo`: An interactive demo showcasing widgets and layouts with live code editing.
    -   `vui_edit`: A standalone version of the editor app.
    -   `vui_png`: A simple PNG pixel editor using `rasterview`.
    -   `vui_settings`: Shows font settings components.

## Styling

-   Widgets and layouts often accept `theme` and `bg_color` parameters.
-   Specific style parameters (like `radius`, `text_color`, `text_size`) can be passed during creation.
-   The library includes support for themes loaded from TOML files (`src/styles.v`, `src/style_*.v`).
-   `src/style_4colors.v` and `src/style_accent_color.v` provide functions (`load_4colors_style`, `load_accent_color_style`) to apply themes based on a few base colors.
-   The `users_resizable.v` example shows adding a theme switching shortcut (`window.add_shortcut_theme()`).

## WebView Integration (`ui.webview`)

Provides a `webview.new_window` function to embed web content.

-   `url`: (string) Initial URL.
-   `title`: (string) Window title.
-   `navigate(url)`: Loads a new URL.
-   `eval_js(script)`: Executes JavaScript in the webview context.

## Further Exploration

-   Explore the specific `Params` struct for each widget/component function in the `src/` and `component/` directories for a full list of options.
-   Run the examples in the `examples/` and `apps/` directories to see the widgets and components in action.
-   Examine `bin/vui_demo.v` for advanced layout techniques and live editing capabilities.
