module vom

// https://www.cnblogs.com/baiyuxuan/p/15430458.html
// 从字符串生成Regex

// AST nodes for regex expressions
pub struct RegexChar {
	c u8
}

pub struct RegexConcat {
	nodes []RegexNode
}

pub struct RegexOr {
	nodes []RegexNode
}

pub struct RegexZeroOrMore {
	node RegexNode
}

pub struct RegexOneOrMore {
	node RegexNode
}

pub type RegexNode = RegexChar | RegexConcat | RegexOr | RegexZeroOrMore | RegexOneOrMore | string

pub struct Regex {
	expr string
mut:
	ind  int
}

fn (mut r Regex) peek() !u8 {
	if r.ind >= r.expr.len {
		return error('end of input')
	}
	return r.expr[r.ind]
}

fn (mut r Regex) next() !u8 {
	c := r.peek()!
	r.ind++
	return c
}

fn (mut r Regex) read(c u8) ! {
	n := r.next()!
	if c != n {
		return error('expected: ${c}')
	}
}

fn (r Regex) end() bool {
	return r.ind >= r.expr.len
}

fn (mut r Regex) parse() !RegexNode {
	r.ind = 0
	return r.parse_expr()!
}

// elem = char | (expr)
fn (mut r Regex) parse_elem() !RegexNode {
	c := r.peek()!
	if c == `(` {
		r.next()!
		rr := r.parse_expr()!
		r.read(`)`)!
		return rr
	} else if c == `.` {
		r.next()!
		return r.parse_any()!
	} else {
		return r.parse_char(r.next()!)!
	}
}

// factor = elem* | elem+ | elem
fn (mut r Regex) parse_factor() !RegexNode {
	mut result := r.parse_elem()!
	if !r.end() {
		c := r.peek() or { return result }
		if c == `*` {
			result = RegexZeroOrMore{
				node: result
			}
			r.next()!
		} else if c == `+` {
			result = RegexOneOrMore{
				node: result
			}
			r.next()!
		}
	}
	return result
}

// term = factor factor ... factor
fn (mut r Regex) parse_term() !RegexNode {
	mut result := r.parse_factor()!
	mut nodes := []RegexNode{}
	nodes << result
	for !r.end() {
		c := r.peek() or { break }
		if c == `)` || c == `|` {
			break
		}
		nodes << r.parse_factor()!
	}
	if nodes.len == 1 {
		return nodes[0]
	}
	return RegexConcat{
		nodes: nodes
	}
}

// expr = term|term|...|term
fn (mut r Regex) parse_expr() !RegexNode {
	mut result := r.parse_term()!
	mut nodes := []RegexNode{}
	nodes << result
	for !r.end() {
		c := r.peek() or { break }
		if c != `|` {
			break
		}
		r.next()!
		nodes << r.parse_term()!
	}
	if nodes.len == 1 {
		return nodes[0]
	}
	return RegexOr{
		nodes: nodes
	}
}

// Helper functions for regex operations
fn (r Regex) parse_any() !RegexNode {
	return '.'
}

fn (r Regex) parse_char(c u8) !RegexNode {
	return RegexChar{
		c: c
	}
}

// Match a regex node against input at a specific position
fn match_at(node RegexNode, input string, pos int) !(string, string, int) {
	if pos >= input.len {
		return error('end of input')
	}
	match node {
		RegexChar {
			if pos < input.len && input[pos] == node.c {
				return input[pos + 1..], input[pos..pos + 1], 1
			}
			return error('char mismatch')
		}
		string {
			// This is the 'any' case
			if pos < input.len {
				return input[pos + 1..], input[pos..pos + 1], 1
			}
			return error('any mismatch')
		}
		RegexConcat {
			mut current_pos := pos
			mut total_len := 0
			mut matched := ''
			mut rest := input[pos..]
			
			for n in node.nodes {
				r, m, l := match_at(n, rest, 0)!
				rest = r
				matched += m
				total_len += l
				current_pos += l
			}
			return rest, matched, total_len
		}
		RegexOr {
			for n in node.nodes {
				rest, matched, len := match_at(n, input, pos) or { continue }
				return rest, matched, len
			}
			return error('no alternative matched')
		}
		RegexZeroOrMore {
			mut current_pos := pos
			mut total_len := 0
			mut matched := ''
			mut rest := input[pos..]
			
			for current_pos < input.len {
				r, m, l := match_at(node.node, rest, 0) or { break }
				rest = r
				matched += m
				total_len += l
				current_pos += l
			}
			return rest, matched, total_len
		}
		RegexOneOrMore {
			mut current_pos := pos
			mut total_len := 0
			mut matched := ''
			mut rest := input[pos..]
			
			// Must match at least once
			r, m, l := match_at(node.node, rest, 0)!
			rest = r
			matched += m
			total_len += l
			current_pos += l
			
			// Then match zero or more times
			for current_pos < input.len {
				r2, m2, l2 := match_at(node.node, rest, 0) or { break }
				rest = r2
				matched += m2
				total_len += l2
				current_pos += l2
			}
			return rest, matched, total_len
		}
	}
}

// Implementation of Parser trait
pub fn (mut r Regex) call(input string) !(string, string, int) {
	ast := r.parse()!
	return match_at(ast, input, 0)!
}



