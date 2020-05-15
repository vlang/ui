module ui

import gx
import eventbus

type SelectionChangedFn fn(voidptr, voidptr) // The second will be ListBox

const (
    _item_height = 20
    _col_list_bkgrnd = gx.White
    _col_item_select = gx.LightBlue
    _col_border = gx.Gray
    _text_offset_y = 3
    _text_offset_x = 5
)

pub struct ListBoxConfig {
mut:
    x              int
    y              int
    width          int
    height         int
    callback       SelectionChangedFn = SelectionChangedFn(0)
    draw_lines     bool = false // Draw a rectangle around every item?
    col_border     gx.Color = _col_border // Item and list border color
    col_bkgrnd     gx.Color = _col_list_bkgrnd // ListBox background color
    col_selected   gx.Color = _col_item_select // Selected item background color
    item_height    int = _item_height
    text_offset_y  int = _text_offset_y
    id             string = '' // To use one callback for multiple ListBoxes
}

// Keys of the items map are IDs of the elements, values are text
pub fn listbox(c ListBoxConfig, items map[string]string) &ListBox {
    mut list := &ListBox{
        x:               if c.draw_lines { c.x } else {c.x - 1}
        y:               if c.draw_lines { c.y } else {c.y - 1}
        width:           c.width
        height:          c.height
        selection:       -1
        clbk:            c.callback
        draw_lines:      c.draw_lines
        col_bkgrnd:      c.col_bkgrnd
        col_selected:    c.col_selected
        col_border:      c.col_border
        item_height:     c.item_height
        text_offset_y:   c.text_offset_y
        id:              c.id
		ui:              0
    }

    for id, text in items {
        list.append_item(id, text, 0)
    }

    return list
}

pub fn (list mut ListBox) add_item(id, text string) {
    list.append_item(id, text, list.get_draw_to(text))
}

pub struct ListBox {
pub mut:
    height          int
    width           int
    x               int
    y               int
    parent          Layout
    ui              &UI
    items           []ListItem
    selection       int = -1
    draw_count      int
    clbk            SelectionChangedFn = SelectionChangedFn(0)
    focused         bool = false
    draw_lines      bool = false
    col_bkgrnd      gx.Color = _col_list_bkgrnd
    col_selected    gx.Color = _col_item_select
    col_border      gx.Color = _col_border
    item_height     int = _item_height
    text_offset_y   int = _text_offset_y
    id              string = ''
}

struct ListItem {
    x           int
    id          string
    list        &ListBox
mut:
    y           int
    text        string
    draw_text   string
}

fn (lb mut ListBox) get_draw_to(text string) int {
    width := lb.ui.ft.text_width(text)
    real_w := lb.width - _text_offset_x * 2
    mut draw_to := text.len
    if width >= real_w {
        draw_to = int(f32(text.len) * (f32(real_w) / f32(width)))
        for draw_to > 1 && lb.ui.ft.text_width(text[0..draw_to]) > real_w {
            draw_to--
        }
    }
    return draw_to
}

fn (lb mut ListBox) append_item(id, text string, draw_to int) {
    lb.items << ListItem{
        x:           lb.x
        y:           lb.y + lb.item_height * lb.items.len
        id:          id
        text:        text
        list:        lb
        draw_text:   text[0..draw_to]
    }
}

pub fn (lb &ListBox) is_selected() bool {
    if lb.selection < 0 || lb.selection >= lb.items.len {
        return false
    }
    return true
}

// Returns the ID and the text of the selected item
pub fn (lb &ListBox) selected() ?(string, string) {
    if !lb.is_selected() {
        return error('Nothing is selected')
    }
    return lb.items[lb.selection].id, lb.items[lb.selection].text
}

// Returns the index of the selected item
pub fn (lb &ListBox) selected_inx() ?int {
    if !lb.is_selected() {
        return error('Nothing is selected')
    }
    return lb.selection
}

pub fn (lb mut ListBox) set_text(id, text string) {
    for i in 0..lb.items.len {
        if lb.items[i].id == id {
            lb.items[i].text = text
            lb.items[i].draw_text = text[0..lb.get_draw_to(text)]
            break
        }
    }
}

pub fn (lb mut ListBox) remove_item(id string) {
    for i in 0..lb.items.len {
        if lb.items[i].id == id {
           lb.remove_inx(i)
           break
        }
    }
}

pub fn (lb mut ListBox) remove_inx(i int) {
   if i < 0 || i >= lb.items.len { return }
   for j in (i+1)..lb.items.len {
       lb.items[j].y -= lb.item_height
   }
   lb.items.delete(i)
}

pub fn (lb mut ListBox) clear() {
    lb.items.clear()
    lb.selection = -1
}

fn (lb mut ListBox) draw_item(li ListItem, selected bool) {
    col := if selected { lb.col_selected } else { lb.col_bkgrnd }
    lb.ui.gg.draw_rect(li.x, li.y, lb.width, lb.item_height, col)
    lb.ui.ft.draw_text_def(li.x+_text_offset_x, li.y+lb.text_offset_y, li.draw_text)

    if lb.draw_lines {
       lb.ui.gg.draw_empty_rect(li.x, li.y, lb.width, lb.item_height, lb.col_border)
    }
}

fn (lb mut ListBox) init(parent Layout) {
    lb.parent = parent
    lb.ui = parent.get_ui()
    lb.draw_count = lb.height / lb.item_height
    lb.text_offset_y = (lb.item_height - lb.ui.ft.text_height('W')) / 2
    if lb.text_offset_y < 0 {
        lb.text_offset_y = 0
    }

    for i, item in lb.items {
        lb.items[i].draw_text = item.text[0..lb.get_draw_to(item.text)]
    }

    mut subscriber := parent.get_subscriber()
    subscriber.subscribe_method(events.on_click, on_click, lb)
    subscriber.subscribe_method(events.on_key_up, on_key_up, lb)
}

fn (lb mut ListBox) draw() {
    lb.ui.gg.draw_rect(lb.x, lb.y, lb.width, lb.height, lb.col_bkgrnd)

    if !lb.draw_lines {
        lb.ui.gg.draw_empty_rect(lb.x, lb.y, lb.width+1, lb.height+1, lb.col_border)
    }

    for inx, item in lb.items {
        if inx >= lb.draw_count { break }
        lb.draw_item(item, inx == lb.selection)
    }
}

fn (lb &ListBox) point_inside(x, y f64) bool {
    return x >= lb.x
        && x <= lb.x + lb.width
        && y >= lb.y
        && y <= lb.y + lb.height
}

fn (li &ListItem) point_inside(x, y f64) bool {
    return x >= li.x
        && x <= li.x + li.list.width
        && y >= li.y
        && y <= li.y + li.list.item_height
}

fn on_click(lb mut ListBox, e &MouseEvent, window &Window) {
    if e.action != 1 { return }
    if !lb.point_inside(e.x, e.y) {
        lb.unfocus()
        return
    }

    lb.focus()

    for inx, item in lb.items {
        if inx >= lb.draw_count { break }
        if item.point_inside(e.x, e.y) {
            if lb.selection != inx {
                lb.selection = inx
                if lb.clbk != 0 {
                    lb.clbk(window.state, lb)
                }
            }
            break
        }
    }
}

// Up and Down keys work on the list when it's focused
fn on_key_up(lb mut ListBox, e &KeyEvent, window &Window ) {
	if !lb.focused {
		return
	}

    match e.key {
        .arrow_down {
            if lb.selection >= lb.draw_count - 1 { return }
            if lb.selection >= lb.items.len - 1 { return }
            lb.selection++
        }
        .arrow_up {
            if lb.selection <= 0 { return }
            lb.selection--
        }
        else { return }
    }

    if lb.clbk != 0 {
        lb.clbk(window.state, lb)
    }
}

fn (list mut ListBox) set_pos(x, y int) {
    list.x = x
    list.y = y
}

fn (list mut ListBox) focus() {
    list.focused = true
}

fn (list mut ListBox) unfocus() {
    list.focused = false
}

fn (list &ListBox) is_focused() bool {
    return list.focused
}

fn (list &ListBox) get_ui() &UI {
    return list.ui
}

fn (list mut ListBox) unfocus_all() {
    list.focused = false
}

fn (list mut ListBox) resize(width, height int) {
    list.width = width
    list.height = height
    list.draw_count = list.height / list.item_height
}

fn (list &ListBox) get_state() voidptr {
    parent := list.parent
    return parent.get_state()
}

fn (list &ListBox) get_subscriber() &eventbus.Subscriber {
    parent := list.parent
    return parent.get_subscriber()
}

fn (list &ListBox) size() (int, int) {
    return list.width, list.height
}

fn (list mut ListBox) propose_size(w, h int) (int, int) {
    list.resize(w, h)
    return list.width, list.height
}
