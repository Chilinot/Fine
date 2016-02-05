all: test


lexer:
	rex source/lexer/lexer.rex -o source/lexer/lexer.rb



test: lexer
	rspec --color test/*.rb
