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
		'a_string':  gx.red
	}
}

fn (mut sh SyntaxHighLighter) parse_chunks(j int, y int, line string) {
	if !sh.is_lang_loaded() {
		return
	}
	// sh.chunks.len = 0 // TODO V should not allow this
	ustr := line.runes()
	sh.ustr = ustr
	for i := 0; i < ustr.len; i++ {
		start := i
		// Comment // #
		if i > 0 && ustr[i - 1] == `/` && ustr[i] == `/` {
			sh.add_chunk(.a_comment, y, start - 1, ustr.len)
			break
		}
		if ustr[i] == `#` {
			sh.add_chunk(.a_comment, y, start, ustr.len)
			break
		}
		// Comment   /*
		// (unless it's /* ustr */ which is a single line)
		if i > 0 && ustr[i - 1] == `/` && ustr[i] == `*` && !(ustr[ustr.len - 2] == `*`
			&& ustr[ustr.len - 1] == `/`) {
			// All after /* is  a comment
			sh.add_chunk(.a_comment, y, start, ustr.len)
			sh.is_ml_comment = true
			break
		}
		if sh.is_ml_comment && !(ustr[ustr.len - 2] == `*` && ustr[ustr.len - 1] == `/`) {
			sh.add_chunk(.a_comment, y, start, ustr.len)
			break
		}
		// End of /**/
		if i > 0 && ustr[i - 1] == `*` && ustr[i] == `/` {
			// All before */ is still a comment
			sh.add_chunk(.a_comment, y, 0, start + 1)
			sh.is_ml_comment = false
			break
		}
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
		// Key
		for i < ustr.len && is_alpha_underscore(int(ustr[i])) {
			i++
		}
		word := ustr[start..i].string()
		// println('word="$word"')
		if word in sh.keys {
			// println('$word is key')
			sh.add_chunk(.a_keyword, y, start, i)
			// println('adding key. len=$sh.chunks.len')
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
	tv := sh.tv
	syntax := sh.langs[sh.lang]
	for typ in syntax.keys() {
		color := syntax[typ]
		for chunk in sh.chunks[typ] {
			// println("$typ: $i) $chunk.x, $chunk.y, $chunk.text")
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
