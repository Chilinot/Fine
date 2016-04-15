class Lexer
macro
    INT_LITERAL                         \d+
    CHAR_LITERAL                        ('\w'|'\s'|'\\n')
    IDENTIFIER                          [a-zA-Z_]\w*
    WHITESPACE                          \s+
    NEWLINE                             \n
    COMMENT                             (\/\*[^\*\/]*\*\/|\/\/.*(\n|\Z))
    KEYWORD                             (char|else|if|int|return|void|while)
    IDENTIFIER_STARTING_WITH_KEYWORD    {KEYWORD}\w+
    OR                                  \|\|
    OPERATOR                            (<=|>=|==|!=|&&|{OR}|=|\*|\+|\-|\/|<|>|!)
    DELIMITER                           (\(|\)|\[|\]|\{|\}|\,|\;)

    # Invalid tokens and errors
    INVALID_COMMENT                     \/\*.*
    INVALID_CHAR                        '\w\w+'
    INVALID_ID                          \d+{IDENTIFIER}
    INVALID_TOKEN                       ({INVALID_ID}|{INVALID_CHAR})
    ERROR                               .+

rule
    {NEWLINE}                           { @current_line += 1; nil }
    {COMMENT}                           { @current_line += text.count "\n"; nil }
    {INVALID_COMMENT}                   { raise LexicalError.new(@current_line, "unclosed comment |#{text}|") }
    {INVALID_TOKEN}                     { raise LexicalError.new(@current_line, "invalid token |#{text}|") }
    {WHITESPACE}
    {INT_LITERAL}                       { [:INT_LITERAL, make_token(text.to_i)] }
    {CHAR_LITERAL}                      { [:CHAR_LITERAL, make_token(text[1..-2])] }
    {IDENTIFIER_STARTING_WITH_KEYWORD}  { [:IDENTIFIER, make_token(text)] }
    {KEYWORD}                           { [text.upcase.to_sym, make_token(text)] }
    {IDENTIFIER}                        { [:IDENTIFIER, make_token(text)] }
    \)                                  { [")", make_token(text)] }
    {OPERATOR}                          { [text, make_token(text)] }
    {DELIMITER}                         { [text, make_token(text)] }
    {ERROR}                             { raise LexicalError.new(@current_line, "unrecognized token |#{text}|") }

inner
    class LexicalError < StandardError
        def initialize(line, error_message)
            @line = line
            @error_message = error_message
        end
        def to_s
            "Lexical error on line #{@line}: #{@error_message}"
        end
    end
    class Token < Struct.new(:line, :value)
        def == v
            value == v
        end
        def to_s; "#{value}" end
        def inspect
            "on line #{line} unexpected token \"#{value}\"|||"
        end
    end
    def make_token value
        Token.new(@lineno, value)
    end
    def tokenize code, show_tokens=false
        @current_line = 1
        scan_setup(code)
        tokens = []
        while token = next_token
            tokens << token
        end
        puts tokens.to_s if show_tokens
        tokens
    end
end
