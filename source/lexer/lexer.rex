class Lexer
macro
    INT                                 \d+
    CHAR                                ('\w'|'\s'|'\\n')
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
    INVALID_CHAR                        '\w\w+'
    INVALID_ID                          \d+{IDENTIFIER}
    INVALID_TOKEN                       ({INVALID_ID}|{INVALID_CHAR})
    ERROR                               .+

rule
    {NEWLINE}                           { @current_line += 1; nil }
    {COMMENT}                           { @current_line += text.count "\n"; nil }
    {INVALID_TOKEN}                     { raise LexicalError.new(@current_line, "invalid token |#{text}|") }
    {WHITESPACE}
    {INT}                               { [:INT, text.to_i] }
    {CHAR}                              { [:CHAR, text[1..-2]] }
    {IDENTIFIER_STARTING_WITH_KEYWORD}  { [:IDENTIFIER, text] }
    {KEYWORD}                           { [:KEYWORD, text.to_sym] }
    {IDENTIFIER}                        { [:IDENTIFIER, text] }
    {OPERATOR}                          { [:OPERATOR, text] }
    {DELIMITER}                         { [:DELIMITER, text] }
    {ERROR}                             { raise LexicalError.new(@current_line, "unrecognized token |#{text}|") }

inner
    class LexicalError < StandardError
        def initialize(line, error_message)
            @line = line
            @error_message = error_message
            # Just print the error for now
            puts to_s
        end
        def to_s
            "\nLexical error on line #{@line}: #{@error_message}"
        end
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

    def tokenize_file filename, show_tokens=false
        tokenize File.read(filename), show_tokens
    end
end
