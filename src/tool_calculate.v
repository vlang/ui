module ui

import regex

// calculation of very simple numeric expression based on regex
// no parenthesis only digit real number

pub struct MiniCalc {
mut:
	op_re    []regex.RE
	paren_re regex.RE
pub mut:
	formula string
	res_str string
	res     f32
}

pub fn mini_calc() MiniCalc {
	mut mc := MiniCalc{}
	for op in [r'\*', r'/', r'\+', r'\-'] {
		query := r'(\-?[\d\.]+)\s*(' + op + r')\s*(\-?[\d\.]+)'
		mc.op_re << regex.regex_opt(query) or { panic(err) }
	}
	mc.paren_re = regex.regex_opt(r'\(\s*([\d\.\+\-\*/]+)\s*\)') or { panic(err) }
	return mc
}

fn compute_repl(re regex.RE, in_txt string, start int, end int) string {
	left := re.get_group_by_id(in_txt, 0)
	op := re.get_group_by_id(in_txt, 1)
	right := re.get_group_by_id(in_txt, 2)
	// println("<$left> <$op> <$right>")
	res := match op {
		'*' { left.f32() * right.f32() }
		'/' { left.f32() / right.f32() }
		'+' { left.f32() + right.f32() }
		'-' { left.f32() - right.f32() }
		else { f32(0) }
	}
	return res.str()
}

pub fn (mut mc MiniCalc) calculate(formula string) f32 {
	mc.formula = formula
	mc.res_str = formula
	for {
		if mc.res_str.contains_any('()') {
			// simplify parenthesis
			mc.simplify_paren()
		} else {
			break
		}
	}
	// compute
	mc.compute_ops()
	mc.res = mc.res_str.f32()
	return mc.res
}

fn (mut mc MiniCalc) compute_ops() {
	for i in 0 .. 4 {
		for {
			// println("prop: $result $op ($query)")
			start, _ := mc.op_re[i].find(mc.res_str)
			if start >= 0 {
				$if mini_calc ? {
					print('res: ${['*', '/', '+', '-'][i]} -> ${mc.res_str}')
				}
				mc.res_str = mc.op_re[i].replace_by_fn(mc.res_str, compute_repl)
				$if mini_calc ? {
					println(' => ${mc.res_str}')
				}
			} else {
				break
			}
		}
	}
}

fn (mut mc MiniCalc) simplify_paren() {
	for {
		start, stop := mc.paren_re.find(mc.res_str)
		if start >= 0 {
			// print("res: $op -> $result")
			formula := mc.res_str[(start + 1)..(stop - 1)]
			// if formula.contains_any("+-*/") {
			mut mc_expr := mini_calc()
			_ := mc_expr.calculate(formula)
			mc.res_str = mc.paren_re.replace_simple(mc.res_str, mc_expr.res_str)
			// } else {
			// 	mc.res_str = mc.paren_re.replace_simple(mc.res_str,r'\0')
			// }
			// println("=> $result")
		} else {
			break
		}
	}
}
