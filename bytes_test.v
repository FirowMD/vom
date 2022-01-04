module vom

fn test_is_a() ? {
	parser := is_a('123456789ABCDEF')
	rest, output := parser('DEADBEEF and others') ?
	assert output == 'DEADBEEF'
	assert rest == ' and others'
}

fn test_is_not() ? {
	parser := is_not(' \t\r\n')
	rest, output := parser('Hello,\tWorld!') ?
	assert output == 'Hello,'
	assert rest == '\tWorld!'
}

fn test_tag() ? {
	parser := tag('- ')
	rest, output := parser('- Something something') ?
	assert output == '- '
	assert rest == 'Something something'
}

fn test_tag_no_case() ? {
	parser := tag_no_case('hello')
	rest, output := parser('HeLLo, World!') ?
	assert output == 'HeLLo'
	assert rest == ', World!'
}

fn test_take() ? {
	parser := take(5)
	rest, output := parser('Hello, world!') ?
	assert output == 'Hello'
	assert rest == ', world!'
}
