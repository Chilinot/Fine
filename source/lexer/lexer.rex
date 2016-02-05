class Lexer
macro
    INT                 \d+
    ID                  [a-zA-Z_]\w*
    WHITESPACE          \s+
    COMMENT             (\/\*.*\*\/|\/\/.*\n)


    INVALID_ID          \d+{ID}
    INVALID_TOKEN       {INVALID_ID}
    ERROR               .+
rule
    {COMMENT}
    {INVALID_TOKEN}     { raise LexicalError.new(text) }
    {WHITESPACE}
    {INT}               { [:INT, text.to_i] }
    {ID}                { [:ID, text] }

    {ERROR}             { raise LexicalError.new(text) }

inner
  class LexicalError < StandardError
      def initialize error
          @error = error
      end
  end
  def tokenize(code)
    scan_setup(code)
    tokens = []
    while token = next_token
      tokens << token
    end
    puts tokens.to_s
    tokens
  end
end
