module ui

import gx

const (
	numeric_set = '0123456789.'.runes()
)

struct Chunk {
	x     int
	y     int
	text  string
	width int
}

struct SyntaxChunk {
	color gx.Color
	font  string
}

type SyntaxStyle = map[string]SyntaxChunk

type SyntaxMapBool = map[string]bool

type SyntaxMapStrings = map[string][]string

type SyntaxMapArrayStrings = map[string][][]string

type SyntaxMapRunes = map[string][]rune

[heap]
struct SyntaxHighLighter {
mut:
	tv               &TextView = unsafe { nil }
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
	sh.tv.update_style(font_name: 'fixed', size: 18)
}

// TODO: documentation
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
		'comment': SyntaxChunk{gx.gray, 'fixed'}
		'keyword': SyntaxChunk{gx.orange, 'fixed_bold'}
		'control': SyntaxChunk{gx.orange, 'fixed_bold'}
		'decl':    SyntaxChunk{gx.black, 'fixed_bold'}
		'types':   SyntaxChunk{gx.purple, 'fixed_bold'}
		'string':  SyntaxChunk{gx.dark_green, 'fixed_bold_italic'}
		'symbols': SyntaxChunk{gx.red, 'fixed_bold'}
		'numeric': SyntaxChunk{gx.blue, 'fixed_bold'}
		'func':    SyntaxChunk{gx.blue, 'fixed'}
	}
}

// TODO: load syntax with json or toml file
fn (mut sh SyntaxHighLighter) load_v() {
	sh.keywords['v'] = {
		'types':   'int,i8,i16,i64,i128,u8,u16,u32,u64,u128,f32,f64,bool,u8,byteptr,charptr,voidptr,string,ustring,rune'.split(',')
		'decl':    '],[,{,},mut:,pub:,pub mut:,mut,pub,unsafe,default,struct,type,enum,struct,union,const'.split(',')
		'control': (
			'for,in,is,or,as,in,is,or,break,continue,match,if,else,go,goto,defer,return,shared,select,rlock,lock,atomic,asm' +
			',$' + 'if,$' + 'else').split(',')
		'keyword': 'fn,module,import,interface,map,assert,sizeof,typeof,__offsetof'.split(',')
		'symbols': '||,&&,&,=,:=,==,<=,>=,>,<,!'.split(',')
		'func':    'print,println'.split(',')
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
		'types':   'int|i8|i16|i64|i128|u8|u16|u32|u64|u128|f32|f64|bool|u8|byteptr|charptr|voidptr|string|ustring|rune'.split('|')
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
		sh.parse_chunk_numeric()
		sh.parse_chunk_between()
		// Keyword
		for keyword, _ in sh.keywords[sh.lang] {
			sh.parse_chunk_keyword(keyword)
		}
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

fn (mut sh SyntaxHighLighter) parse_chunk_between() {
	// String or betwwen one same rune
	for typ, vals in sh.between_one_rune[sh.lang] {
		for val in vals {
			sh.parse_chunk_between_one_rune(typ, val)
		}
	}
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
		if sh.i < sh.ustr.len - 1 {
			sh.i++
			sh.start = sh.i
		}
	}
}

fn (mut sh SyntaxHighLighter) parse_chunk_numeric() {
	if !sh.is_alpha_underscore_before(sh.start) && ((sh.ustr[sh.i] in ui.numeric_set)
		|| sh.ustr[sh.i] == `-`) {
		sh.i++
		for {
			if sh.i == sh.ustr.len {
				sh.i--
				break
			}
			if sh.ustr[sh.i] in ui.numeric_set {
				sh.i++
			} else {
				sh.i--
				break
			}
		}
		if sh.i == sh.start && sh.ustr[sh.i] in [`-`, `.`] {
			// sh.i--
		} else {
			sh.add_chunk('numeric', sh.y, sh.start, sh.i + 1)
			// println("numeric ${sh.ustr[sh.start..(sh.i + 1)].string()}")
			if sh.i < sh.ustr.len - 1 {
				sh.i++
			}
			sh.start = sh.i
		}
	}
}

fn (mut sh SyntaxHighLighter) parse_chunk_keyword(typ string) {
	mut i := -1
	for sh.i < sh.ustr.len && is_alpha_and_symbols(int(sh.ustr[sh.i])) {
		sh.i++
		word := sh.ustr[sh.start..sh.i].string()
		if word in sh.keywords[sh.lang][typ] && sh.is_not_included(sh.start, sh.i) {
			// println("$typ $word ") // ${sh.keywords[sh.lang][typ]}")
			i = sh.i
		}
	}
	if i > 0 {
		sh.i = i
		sh.add_chunk(typ, sh.y, sh.start, sh.i)
		// println("$typ ${sh.ustr[sh.start..sh.i].string()} ") // ${sh.keywords[sh.lang][typ]}")
		sh.start = sh.i
	} else {
		sh.i = sh.start + 1
	}
}

fn (sh &SyntaxHighLighter) is_alpha_underscore_before(i int) bool {
	return i > 0 && is_alpha_underscore(int(sh.ustr[i - 1]))
}

fn (sh &SyntaxHighLighter) is_alpha_underscore_after(i int) bool {
	return i < sh.ustr.len - 1 && is_alpha_underscore(int(sh.ustr[i + 1]))
}

fn (sh &SyntaxHighLighter) is_not_included(from int, to int) bool {
	return !sh.is_alpha_underscore_before(from) && !sh.is_alpha_underscore_after(to - 1)
}

fn (mut sh SyntaxHighLighter) add_chunk(typ string, y int, start int, end int) {
	x := sh.tv.tb.x + sh.tv.left_margin + int(sh.tv.text_width_additive(sh.ustr[0..start].string()))
	// x := sh.tv.tb.x + sh.tv.left_margin + int(sh.tv.text_width(sh.ustr[0..start].string()))
	text := sh.ustr[start..end].string()
	chunk := Chunk{
		x: x
		y: y
		text: text
		width: int(sh.tv.text_width_additive(text))
		// width: int(sh.tv.text_width(text))
	}
	sh.chunks[typ] << chunk
}

// Not used yet since one needs to find out how to use it to compute chunks only once when needed
fn (mut sh SyntaxHighLighter) parse_all_lines() {
	tv := sh.tv
	// only visible text lines
	mut y := tv.tb.y + textbox_padding_y
	if tv.tb.has_scrollview {
		y += (tv.tlv.from_j) * tv.line_height
	}
	sh.reset_chunks()
	for j, line in tv.tlv.lines[tv.tlv.from_j..(tv.tlv.to_j + 1)] {
		sh.parse_chunks(j, y, line)
		y += tv.line_height
	}
}

fn (mut sh SyntaxHighLighter) draw_device_chunks(d DrawDevice) {
	if !sh.is_lang_loaded() {
		return
	}
	// println("-".repeat(80))
	tv := sh.tv
	style := sh.styles[sh.style]
	for typ in style.keys() {
		color, font := style[typ].color, style[typ].font
		for chunk in sh.chunks[typ] {
			// println("$typ: $chunk.x, $chunk.y, $chunk.text")
			// fix background (not needed with real fixed font)
			$if !no_tb_clear_sh ? {
				d.draw_rect_filled(chunk.x, chunk.y, chunk.width, tv.line_height, tv.tb.style.bg_color)
			}
			tv.draw_device_styled_text(d, chunk.x, chunk.y, chunk.text,
				color: color
				font_name: font
			)
			tv.load_style()
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

fn is_alpha(r u8) bool {
	return (r >= `a` && r <= `z`) || (r >= `A` && r <= `Z`) || (r >= `0` && r <= `9`)
}

fn is_whitespace(r u8) bool {
	return r == ` ` || r == `\t`
}

fn is_alpha_underscore(r int) bool {
	return is_alpha(u8(r)) || u8(r) == `_`
}

fn is_alpha_and_symbols(r int) bool {
	return is_alpha(u8(r))
		|| u8(r) in [`_`, `#`, `$`, `:`, `=`, `&`, `<`, `>`, `!`, `|`, `+`, `-`, `[`, `]`, `{`, `}`, `(`, `)`]
}
