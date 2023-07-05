module ui

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

fn text_lines_size(lines []string, u &UI) (int, int) {
	mut width, mut height := 0, 0
	mut tw, mut th := 0, 0
	dd := u.dd
	for line in lines {
		tw, th = dd.text_size(line)
		// println("tt line: $line -> ($tw, $th)")
		if tw > width {
			width = tw
		}
		height += th
	}
	return width, height
}
