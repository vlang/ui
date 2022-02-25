module ui

import gx
// inspired from ved

// For syntax highlighting
enum ChunkKind {
	a_string = 1
	a_comment = 2
	a_keyword = 3
}

struct Chunk {
	x    int
	y    int
	text string
}

type SyntaxStyle = map[string]gx.Color

[heap]
struct SyntaxHighLighter {
mut:
	tv           &TextView = 0
	ustr         []rune
	chunks       map[string][]Chunk
	lang         string
	langs        map[string]SyntaxStyle
	is_multiline map[string]bool
	keys         []string
	// for loop
	i     int
	j     int
	start int
	y     int
}

fn syntaxhighlighter() &SyntaxHighLighter {
	return &SyntaxHighLighter{}
}

fn (mut sh SyntaxHighLighter) init(tv &TextView) {
	sh.load_v()
	sh.set_lang('')
	sh.is_multiline = {
		'/*': false
	}
	unsafe {
		sh.tv = tv
	}
}

pub fn (mut sh SyntaxHighLighter) set_lang(ext string) {
	sh.lang = if ext.len > 0 && ext[0..1] == '.' {
		if ext[1..] in sh.langs.keys() { ext[1..] } else { '' }
	} else {
		''
	}
}

fn (sh &SyntaxHighLighter) is_lang_loaded() bool {
	return sh.lang != ''
}

fn (mut sh SyntaxHighLighter) load_v() {
	keys := 'case shared defer none match pub struct interface in sizeof assert enum import go ' +
		'return module fn if for break continue asm unsafe mut is ' +
		'type const else true else for false use $' + 'if $' + 'else'
	sh.keys = keys.split(' ')
	sh.langs = {}
	sh.langs['v'] = {
		'a_comment': gx.gray
		'a_keyword': gx.blue
		'a_string':  gx.dark_green
	}
}

fn (mut sh SyntaxHighLighter) parse_chunks(j int, y int, line string) {
	if !sh.is_lang_loaded() {
		return
	}

	sh.j, sh.y = j, y

	if j == 0 {
		for k, _ in sh.is_multiline {
			sh.is_multiline[k] = false
		}
	}

	sh.ustr = line.runes()
	l := line.trim_space()
	// single line comment
	if sh.parse_chunk_oneline_comment(.a_comment, '//', l) {
		return
	}
	if sh.parse_chunk_oneline_comment(.a_comment, '#', l) {
		return
	}

	// multilines or single line
	if sh.parse_chunk_multiline_comment(.a_comment, '/*', '*/', l) {
		return
	}

	// other stuff
	sh.i = 0
	for sh.i < sh.ustr.len {
		sh.start = sh.i
		// String
		sh.parse_chunk_between_one_rune(.a_string, `'`)
		sh.parse_chunk_between_one_rune(.a_string, `"`)
		// Keyword
		sh.parse_chunk_keyword(.a_keyword)
		sh.i++
	}
}

fn (mut sh SyntaxHighLighter) parse_chunk_oneline_comment(typ ChunkKind, comment_sep string, line_trim string) bool {
	// single line comment
	if line_trim.starts_with(comment_sep) {
		sh.add_chunk(typ, sh.y, 0, sh.ustr.len)
		return true
	} else {
		return false
	}
}

fn (mut sh SyntaxHighLighter) parse_chunk_multiline_comment(typ ChunkKind, comment_start string, comment_stop string, line_trim string) bool {
	if line_trim.starts_with(comment_start) {
		sh.is_multiline[comment_start] = !line_trim.ends_with(comment_stop)
		sh.add_chunk(.a_comment, sh.y, 0, sh.ustr.len)
		return true
	}
	if sh.is_multiline[comment_start] && !line_trim.contains(comment_stop) {
		sh.add_chunk(.a_comment, sh.y, 0, sh.ustr.len)
		return true
	}
	if sh.is_multiline[comment_start] && line_trim.contains(comment_stop)
		&& line_trim.ends_with(comment_stop) {
		sh.is_multiline[comment_start] = false
		sh.add_chunk(typ, sh.y, 0, sh.ustr.len)
		return true
	}
	return false
}

fn (mut sh SyntaxHighLighter) parse_chunk_between_one_rune(typ ChunkKind, sep rune) {
	if sh.ustr[sh.i] == sep {
		sh.i++
		for sh.i < sh.ustr.len - 1 && sh.ustr[sh.i] != sep {
			sh.i++
		}
		if sh.i >= sh.ustr.len {
			sh.i = sh.ustr.len - 1
		}
		sh.add_chunk(typ, sh.y, sh.start, sh.i + 1)
	}
}

fn (mut sh SyntaxHighLighter) parse_chunk_keyword(typ ChunkKind) {
	for sh.i < sh.ustr.len && is_alpha_underscore(int(sh.ustr[sh.i])) {
		sh.i++
	}
	word := sh.ustr[sh.start..sh.i].string()
	if word in sh.keys {
		sh.add_chunk(typ, sh.y, sh.start, sh.i)
	}
}

fn (mut sh SyntaxHighLighter) add_chunk(typ ChunkKind, y int, start int, end int) {
	x := sh.tv.tb.x + sh.tv.left_margin + sh.tv.text_width(sh.ustr[0..start].string())
	text := sh.ustr[start..end].string()
	chunk := Chunk{
		x: x
		y: y
		text: text
	}
	sh.chunks[typ.str()] << chunk
}

fn (mut sh SyntaxHighLighter) draw_chunks() {
	if !sh.is_lang_loaded() {
		return
	}
	// println("-".repeat(80))
	tv := sh.tv
	syntax := sh.langs[sh.lang]
	for typ in syntax.keys() {
		color := syntax[typ]
		for chunk in sh.chunks[typ] {
			// println("$typ: $chunk.x, $chunk.y, $chunk.text")
			// fix background
			tv.tb.ui.gg.draw_rect_filled(chunk.x, chunk.y, tv.text_width(chunk.text),
				tv.line_height, tv.tb.bg_color)
			tv.draw_styled_text(chunk.x, chunk.y, chunk.text, color: color)
		}
	}
}

fn (mut sh SyntaxHighLighter) reset_chunks() {
	if !sh.is_lang_loaded() {
		return
	}
	sh.chunks = {}
	for typ in sh.langs[sh.lang].keys() {
		sh.chunks[typ] = []
	}
}

fn is_alpha(r byte) bool {
	return (r >= `a` && r <= `z`) || (r >= `A` && r <= `Z`) || (r >= `0` && r <= `9`)
}

fn is_whitespace(r byte) bool {
	return r == ` ` || r == `\t`
}

fn is_alpha_underscore(r int) bool {
	return is_alpha(byte(r)) || byte(r) == `_` || byte(r) == `#` || byte(r) == `$`
}
