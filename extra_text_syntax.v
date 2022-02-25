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
	tv            &TextView = 0
	ustr          []rune
	chunks        map[string][]Chunk
	lang          string
	langs         map[string]SyntaxStyle
	is_ml_comment bool
	keys          []string
}

fn syntaxhighlighter() &SyntaxHighLighter {
	return &SyntaxHighLighter{}
}

fn (mut sh SyntaxHighLighter) init(tv &TextView) {
	sh.load_v()
	sh.set_lang('')
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
	// sh.chunks.len = 0 // TODO V should not allow this
	ustr := line.runes()
	sh.ustr = ustr
	// single line comment
	l := line.trim_space()
	if l.starts_with('//') || l.starts_with('#') {
		sh.add_chunk(.a_comment, y, 0, ustr.len)
		return
	}

	// multilines or single line
	if j == 0 {
		sh.is_ml_comment = false
	}
	if line.len > 1 && line[0..2] == '/*' {
		sh.is_ml_comment = line[(line.len - 2)..line.len] != '*/'
		sh.add_chunk(.a_comment, y, 0, ustr.len)
		return
	}
	if sh.is_ml_comment && !line.contains('*/') {
		sh.add_chunk(.a_comment, y, 0, ustr.len)
		return
	}
	if sh.is_ml_comment && line.contains('*/') && line[(line.len - 2)..line.len] == '*/' {
		sh.is_ml_comment = false
		sh.add_chunk(.a_comment, y, 0, ustr.len)
		return
	}

	// other stuff
	for i := 0; i < ustr.len; i++ {
		start := i
		// String
		if ustr[i] == `'` {
			i++
			for i < ustr.len - 1 && ustr[i] != `'` {
				i++
			}
			if i >= ustr.len {
				i = ustr.len - 1
			}
			sh.add_chunk(.a_string, y, start, i + 1)
		}
		if ustr[i] == `"` {
			i++
			for i < ustr.len - 1 && ustr[i] != `"` {
				i++
			}
			if i >= ustr.len {
				i = ustr.len - 1
			}
			sh.add_chunk(.a_string, y, start, i + 1)
		}
		// Keyword
		for i < ustr.len && is_alpha_underscore(int(ustr[i])) {
			i++
		}
		word := ustr[start..i].string()
		if word in sh.keys {
			sh.add_chunk(.a_keyword, y, start, i)
		}
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
