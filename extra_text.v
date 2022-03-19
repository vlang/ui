module ui

const (
	word_wrap_id = '\n'
)

pub fn text_x_from_pos<T>(w &T, text string, x int) int {
	ustr := text.runes()
	if x > ustr.len {
		// println('warning: text_x_from_pos $x > $ustr.len')
		x = ustr.len
	}
	left := ustr[..x].string()
	return text_width(w, left)
}

pub fn text_xminmax_from_pos<T>(w &T, text string, x1 int, x2 int) (int, int) {
	ustr := text.runes()
	mut x_min, mut x_max := if x1 < x2 { x1, x2 } else { x2, x1 }
	if x_max > ustr.len {
		// println('warning: text_xminmax_from_pos $x_max > $ustr.len')
		x_max = ustr.len
	}
	if x_min < 0 {
		// println('warning: text_xminmax_from_pos $x_min < 0')
		x_min = 0
	}
	// println("xminmax: ${ustr.len} $x_min $x_max")
	left := ustr[..x_min].string()
	right := ustr[x_max..].string()
	ww, lw, rw := text_width(w, text), text_width(w, left), text_width(w, right)
	return lw, ww - lw - rw
}

pub fn text_pos_from_x<T>(w &T, text string, x int) int {
	if x <= 0 {
		return 0
	}
	mut prev_width := 0
	ustr := text.runes()
	for i in 0 .. ustr.len {
		width := text_width(w, ustr[..i].string())
		width2 := if i < ustr.len { text_width(w, ustr[..(i + 1)].string()) } else { width }
		if (prev_width + width) / 2 <= x && x <= (width + width2) / 2 {
			return i
		}
		prev_width = width
	}
	return ustr.len
}

fn word_wrap_to_line_by_width<T>(w &T, s string, max_line_width int) ([]string, []int) {
	words := s.split(' ')
	mut line := ''
	mut line_width := 0
	mut text_lines := []string{}
	mut word_wrap, mut cpt := []int{}, 0
	for i, word in words {
		if i == 0 { // at least the first
			line = word
			line_width = text_width(w, word)
		} else {
			word_width := text_width(w, ' ' + word)
			if line_width + word_width < max_line_width {
				line += ' ' + word
				line_width += word_width
			} else {
				text_lines << line
				word_wrap << cpt
				line = word
				line_width = word_width
				cpt++
			}
		}
	}
	if line_width > 0 {
		text_lines << line
		word_wrap << cpt
	}
	return text_lines, word_wrap
}

fn word_wrap_text_to_lines_by_width<T>(w &T, s string, max_line_width int) ([]string, []int) {
	lines := s.split('\n')
	mut word_wrapped_lines, mut word_wrap_ind := []string{}, []int{}
	for line in lines {
		ww_lines, ww_ind := word_wrap_to_line_by_width(w, line, max_line_width)
		word_wrapped_lines << ww_lines
		word_wrap_ind << ww_ind
	}
	// println('tl: $word_wrapped_lines ww: $word_wrap_ind')
	return word_wrapped_lines, word_wrap_ind
}

fn word_wrap_join(lines []string, ind []int) string {
	mut res := ''
	// println("lines: $lines, ind: $ind")
	for i, line in lines {
		sp := if i == 0 {
			''
		} else if ind[i] > 0 {
			' '
		} else {
			'\n'
		}
		res += sp + line
	}
	// println("res: $res")
	return res
}

// get text position from row i and column j
pub fn text_lines_pos_at(lines []string, i int, j int) int {
	mut pos := 0
	for k in 0 .. j {
		pos += lines[k].runes().len + 1 // +1 for \n or space
	}
	pos += i
	// println('text_lines_pos_at: ($i, $j) -> $pos ')
	return pos
}

// get row and column from text position
pub fn text_lines_row_column_at(lines []string, pos int) (int, int) {
	if pos == 0 {
		return 0, 0
	}
	mut j := 0
	mut total_len, mut ustr_len := 0, 0
	for line in lines {
		ustr_len = line.runes().len + 1
		total_len += ustr_len
		if pos > total_len {
			j++
		} else {
			total_len -= ustr_len
			break
		}
	}
	// println('text_lines_row_column_at: $pos -> ($pos - $total_len, $j)')
	return pos - total_len, j
}

// Initially inside ui_linux_c.v
fn word_wrap_to_lines(s string, max_line_length int) []string {
	words := s.split(' ')
	mut line := []string{}
	mut line_len := 0
	mut text_lines := []string{}
	for word in words {
		word_len := word.runes().len
		if line_len + word_len < max_line_length {
			line << word
			line_len += word_len + 1
			continue
		} else {
			text_lines << line.join(' ')
			line = []
			line_len = 0
		}
	}
	if line_len > 0 {
		text_lines << line.join(' ')
	}
	return text_lines
}

fn word_wrap_text_to_lines(s string, max_line_length int) []string {
	lines := s.split('\n')
	mut word_wrapped_lines := []string{}
	for line in lines {
		word_wrapped_lines << word_wrap_to_lines(line, max_line_length)
	}
	return word_wrapped_lines
}

fn text_lines_size(lines []string, ui &UI) (int, int) {
	mut width, mut height := 0, 0
	mut tw, mut th := 0, 0
	for line in lines {
		tw, th = ui.gg.text_size(line)
		// println("tt line: $line -> ($tw, $th)")
		if tw > width {
			width = tw
		}
		height += th
	}
	return width, height
}

/*
// Playing with Styled Text

struct TextChunk {
	text  string
	start int
	stop  int
	cfg   gx.TextCfg
}

pub struct TextContext {
	chunks []TextChunk
	colors map[string]gx.Color
	styles map[string]gx.TextCfg
}

struct TextView {
	x       int
	y       int
	width   int
	height  int
	context &TextContext
}


* default: {style: "", size: 10, color: black}

* start:

	- style: normal "", italic {i], bold {b], underline {u]
	- size: uint8 (ex: {12])
	- color: r,g,b,a or hexa (0x00000000) string lowercase (ex: {red])
	- font-family: string capitalized

- combined: {...|...|...]

end:

- idem with closing [...} or [...|...|...}
- empty [} means last opened


current:

custom style: blurr

stack of style operations:

{b] {t] [b} [t}
*/
