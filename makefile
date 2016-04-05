all: test

lexer:
	rex lib/lexer/lexer.rex -o lib/lexer/lexer.rb

test: lexer
	rspec --color test/*.rb
