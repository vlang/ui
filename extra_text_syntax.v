module ui

import gx

struct Chunk {
	x    int
	y    int
	text string
}

type SyntaxStyle = map[string]gx.Color

type SyntaxMapBool = map[string]bool

type SyntaxMapStrings = map[string][]string

type SyntaxMapArrayStrings = map[string][][]string

type SyntaxMapRunes = map[string][]rune

[heap]
struct SyntaxHighLighter {
mut:
	tv               &TextView = 0
	ustr             []rune
	chunks           map[string][]Chunk
	lang             string
	lang_exts        SyntaxMapStrings
	style            string = 'default'
	styles           map[string]SyntaxStyle
	is_multiline     map[string]SyntaxMapBool
	keywords         map[string]SyntaxMapStrings
	singleline       map[string]SyntaxMapStrings
	multiline        map[string]SyntaxMapArrayStrings
	between_one_rune map[string]SyntaxMapRunes
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
	unsafe {
		sh.tv = tv
	}
	// stuff for highlighting features
	sh.styles = {}
	sh.keywords = {}
	sh.singleline = {}
	sh.multiline = {}
	sh.between_one_rune = {}
	sh.is_multiline = {}
	// load language
	sh.lang_exts = {
		'v': ['.v', '.vv', '.vsh']
		'c': ['.h', '.c']
	}
	sh.load_v()
	sh.load_c()
	sh.set_lang('')
	sh.load_default_style()
}

pub fn (mut sh SyntaxHighLighter) set_lang(ext string) {
	sh.lang = ''
	if ext.len == 0 {
		return
	}
	for lang, exts in sh.lang_exts {
		if ext in exts {
			sh.lang = lang
			return
		}
	}
}

fn (sh &SyntaxHighLighter) is_lang_loaded() bool {
	return sh.lang != ''
}

// TODO: load with json or toml file
fn (mut sh SyntaxHighLighter) load_default_style() {
	sh.styles['default'] = {
		'comment': gx.gray
		'keyword': gx.blue
		'control': gx.orange
		'decl':    gx.red
		'types':   gx.purple
		'string':  gx.dark_green
	}
}

// TODO: load syntax with json or toml file
fn (mut sh SyntaxHighLighter) load_v() {
	sh.keywords['v'] = {
		'types':   'int|i8|i16|i64|i128|u8|u16|u32|u64|u128|f32|f64|bool|byte|byteptr|charptr|voidptr|string|ustring|rune'.split('|')
		'decl':    'mut|pub|unsafe|default|module|import|const|interface'.split('|')
		'control': (
			'enum|in|is|or|as|in|is|or|break|continue|match|if|else|for|go|goto|defer|return|shared|select|rlock|lock|atomic|asm' +
			'|$' + 'if|$' + 'else').split('|')
		'keyword': 'fn|type|enum|struct|union|interface|map|assert|sizeof|typeof|__offsetof'.split('|')
	}
	sh.singleline['v'] = {
		'comment': ['//', '#']
	}
	sh.multiline['v'] = {
		'comment': [['/*', '*/']]
	}
	sh.between_one_rune['v'] = {
		'string': [`'`, `"`, `\``]
	}
	sh.is_multiline['v'] = {
		'/*': false
	}
}

fn (mut sh SyntaxHighLighter) load_c() {
	sh.keywords['c'] = {
		'types':   'int|i8|i16|i64|i128|u8|u16|u32|u64|u128|f32|f64|bool|byte|byteptr|charptr|voidptr|string|ustring|rune'.split('|')
		'decl':    'mut|pub|unsafe|default|module|import|const|interface'.split('|')
		'control': (
			'enum|in|is|or|as|in|is|or|break|continue|match|if|else|for|go|goto|defer|return|shared|select|rlock|lock|atomic|asm' +
			'|$' + 'if|$' + 'else').split('|')
		'keyword': 'fn|type|enum|struct|union|interface|map|assert|sizeof|typeof|__offsetof'.split('|')
	}
	sh.singleline['c'] = {
		'comment': ['//', '#']
	}
	sh.multiline['c'] = {
		'comment': [['/*', '*/']]
	}
	sh.between_one_rune['c'] = {
		'string': [`'`, `"`, `\``]
	}
	sh.is_multiline['c'] = {
		'/*': false
	}
}

fn (mut sh SyntaxHighLighter) parse_chunks(j int, y int, line string) {
	if !sh.is_lang_loaded() {
		return
	}
	sh.j, sh.y = j, y

	if j == 0 {
		for k, _ in sh.is_multiline[sh.lang] {
			sh.is_multiline[sh.lang][k] = false
		}
	}

	sh.ustr = line.runes()
	l := line.trim_space()
	// single line comment
	for typ, vals in sh.singleline[sh.lang] {
		for val in vals {
			if sh.parse_chunk_oneline_comment(typ, val, l) {
				return
			}
		}
	}

	// multilines or single line
	for typ, vals in sh.multiline[sh.lang] {
		for val in vals {
			if sh.parse_chunk_multiline_comment(typ, val[0], val[1], l) {
				return
			}
		}
	}

	// loop stuff
	sh.i = 0
	for sh.i < sh.ustr.len {
		sh.start = sh.i
		// String or betwwen one same rune
		for typ, vals in sh.between_one_rune[sh.lang] {
			for val in vals {
				sh.parse_chunk_between_one_rune(typ, val)
			}
		}
		// Keyword
		for keyword, _ in sh.keywords[sh.lang] {
			sh.parse_chunk_keyword(keyword)
		}
		sh.i++
	}
}

fn (mut sh SyntaxHighLighter) parse_chunk_oneline_comment(typ string, comment_sep string, line_trim string) bool {
	// single line comment
	if line_trim.starts_with(comment_sep) {
		sh.add_chunk(typ, sh.y, 0, sh.ustr.len)
		return true
	} else {
		return false
	}
}

fn (mut sh SyntaxHighLighter) parse_chunk_multiline_comment(typ string, comment_start string, comment_stop string, line_trim string) bool {
	if line_trim.starts_with(comment_start) {
		sh.is_multiline[sh.lang][comment_start] = !line_trim.ends_with(comment_stop)
		sh.add_chunk(typ, sh.y, 0, sh.ustr.len)
		return true
	}
	if sh.is_multiline[sh.lang][comment_start] && !line_trim.contains(comment_stop) {
		sh.add_chunk(typ, sh.y, 0, sh.ustr.len)
		return true
	}
	if sh.is_multiline[sh.lang][comment_start] && line_trim.contains(comment_stop)
		&& line_trim.ends_with(comment_stop) {
		sh.is_multiline[sh.lang][comment_start] = false
		sh.add_chunk(typ, sh.y, 0, sh.ustr.len)
		return true
	}
	return false
}

fn (mut sh SyntaxHighLighter) parse_chunk_between_one_rune(typ string, sep rune) {
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

fn (mut sh SyntaxHighLighter) parse_chunk_keyword(typ string) {
	for sh.i < sh.ustr.len && is_alpha_underscore(int(sh.ustr[sh.i])) {
		sh.i++
	}
	word := sh.ustr[sh.start..sh.i].string()
	if word in sh.keywords[sh.lang][typ] {
		sh.add_chunk(typ, sh.y, sh.start, sh.i)
	}
}

fn (mut sh SyntaxHighLighter) add_chunk(typ string, y int, start int, end int) {
	x := sh.tv.tb.x + sh.tv.left_margin + sh.tv.text_width(sh.ustr[0..start].string())
	text := sh.ustr[start..end].string()
	chunk := Chunk{
		x: x
		y: y
		text: text
	}
	sh.chunks[typ] << chunk
}

fn (mut sh SyntaxHighLighter) draw_chunks() {
	if !sh.is_lang_loaded() {
		return
	}
	// println("-".repeat(80))
	tv := sh.tv
	style := sh.styles[sh.style]
	for typ in style.keys() {
		color := style[typ]
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
	for typ in sh.styles[sh.style].keys() {
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
