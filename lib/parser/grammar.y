class Parser
# ---- [precedance table] ----------------------------------------------
prechigh
# Prefix unary operators
nonassoc "!" # 14R?
# Infix operators
left "*" "/" # 13L
left "+" "-" # 12L
left "<" ">" "<=" ">=" # 10L
left "==" "!=" #9L
left "&&" # 5L
right "=" # 2R
preclow

# ---- [token declearations] -------------------------------------------
token IDENTIFIER
token CHAR ELSE IF INT RETURN VOID WHILE
token INT_LITERAL CHAR_LITERAL
# ---- [expected number of S/R conflict] -------------------------------
# expect 1
# ---- [options] -------------------------------------------------------
# ---- [semantic value convertion] -------------------------------------
# ---- [start rule] ----------------------------------------------------
start program
# ---- [grammar] -------------------------------------------------------
rule

    program : topdec_list                                   { result = Program.new(val[0]) }

    topdec_list : /* empty */                               { result = [] }
                | topdec topdec_list                        { result = val[1].unshift(val[0]) }

    topdec : typename IDENTIFIER "(" formals ")" funbody    { case val[5]
                                                                when :empty then result = ExternFunctionDeclaration.new(val[0], val[1].value, val[3])
                                                                else result = FunctionDeclaration.new(val[0], val[1].value, val[3], val[5])
                                                              end }
           | vardec ";"

    vardec : scalardec
           | arraydec

    scalardec : typename IDENTIFIER                         { if val[0] != :VOID
                                                                result = VarDeclaration.new(val[0], val[1].value)
                                                              else
                                                                  raise SyntaxError.new(val[1].line, "variable #{val[1]} can not be of type void")
                                                              end }

    arraydec  : typename IDENTIFIER "[" INT_LITERAL "]"     { if val[0] != :VOID
                                                                result = ArrayDeclaration.new(val[0], val[1].value, val[3].value)
                                                              else
                                                                  raise SyntaxError.new(val[1].line, "Array #{val[1].value} can not be of type void")
                                                              end }


    typename : INT                                          { result = val[0].value.upcase.to_sym }
             | CHAR                                         { result = val[0].value.upcase.to_sym }
             | VOID                                         { result = val[0].value.upcase.to_sym }

    funbody : "{" locals stmts "}"                          { result = FunctionBody.new(val[1], val[2]) }
            | ";"                                           { result = :empty }

    formals : VOID                                          { result = [] }
            | formal_list                                   { result = val[0] }

    formal_list : ")"                                       { raise SyntaxError.new(val[0].line, "expected void or parameters, but got \")\"") }
                | formaldec                                 { result = [val[0]] }
                | formaldec "," formal_list                 { result = val[2].unshift(val[0]) }

    formaldec : scalardec
              | typename IDENTIFIER "[" "]"                 { if val[0] != :VOID
                                                                result = ArrayDeclaration.new(val[0], val[1].value)
                                                              else
                                                                  raise SyntaxError.new(val[1].line, "Array #{val[1].value} can not be of type void")
                                                              end }


    locals : /* empty */                                    { result = [] }
           | vardec ";" locals                              { result = val[2].unshift(val[0]) }

    stmts : /* empty */                                     { result = [] }
          | ";" stmts                                       { result = val[1] }
          | stmt stmts                                      { result = val[1].unshift(val[0]) }

    stmt : expr ";"                                         { result = val[0] }
         | return                                           { result = val[0] }
         | while
         | if                                               { result = val[0] }
         | block                                            { result = val[0] }

    while : WHILE condition block                           { result = While.new(val[1], val[2]) }

    return : RETURN expr ";"                                { result = Return.new(val[1]) }
           | RETURN ";"                                     { result = Return.new(:VOID) }

      if : IF condition block else                          { result = If.new(val[1], val[2], val[3]) }
    else : /* empty */
         | ELSE if                                          { result = [val[1]] }
         | ELSE block                                       { result = val[1] }

    block : "{" stmts "}"                                   { result = val[1] }

    condition : "(" ")"                                     { raise SyntaxError.new(val[1].line, "expected condition, but found \")\"") }
              | "(" expr ")"                                { result = val[1] }

    expr : INT_LITERAL                                      { result = Constant.new(:INT, val[0].value) }
         | CHAR_LITERAL                                     { result = Constant.new(:CHAR, val[0].value) }
         | IDENTIFIER                                       { result = Identifier.new(val[0].value) }
         | IDENTIFIER "[" expr "]"                          { result = ArrayLookup.new(val[0].value, val[2])  }
         | expr "+" expr                                    { result = AddNode.new(val[0], val[2]) }
         | expr "-" expr                                    { result = SubNode.new(val[0], val[2]) }
         | expr "*" expr                                    { result = MulNode.new(val[0], val[2]) }
         | expr "/" expr                                    { result = DivNode.new(val[0], val[2]) }
         | expr "<" expr                                    { result = LessThanNode.new(val[0], val[2]) }
         | expr ">" expr                                    { result = GreaterThanNode.new(val[0], val[2]) }
         | expr "<=" expr                                   { result = LessEqualNode.new(val[0], val[2]) }
         | expr ">=" expr                                   { result = GreaterEqualNode.new(val[0], val[2]) }
         | expr "!=" expr                                   { result = NotEqualNode.new(val[0], val[2]) }
         | expr "==" expr                                   { result = EqualNode.new(val[0], val[2]) }
         | expr "&&" expr                                   { result = AndNode.new(val[0], val[2]) }
         | expr "=" expr                                    { result = AssignNode.new(val[0], val[2]) }
         | "-" expr                                         { result = UnaryMinus.new(val[1]) }
         | "!" expr                                         { result = Not.new(val[1]) }
         | IDENTIFIER "(" actuals ")"                       { result = FunctionCall.new(val[0].value, val[2]) }
         | "(" expr ")"                                     { result = val[1] }

    actuals : /* empty */                                   { result = [] }
            | expr_list                                     { result = val[0] }

    expr_list : expr                                        { result = [val[0]] }
              | expr "," ")"                                { raise SyntaxError.new(val[2].line, "expected expression, but found \")\"")  }
              | expr "," expr_list                          { result = val[2].unshift(val[0]) }

end
# ---- [header] --------------------------------------------------------
---- header
require_relative "../lexer/lexer.rb"
require_relative "../nodes.rb"

# ---- [inner] ---------------------------------------------------------
---- inner
class SyntaxError < StandardError
    def initialize(line, error_message)
        @line = line
        @error_message = error_message
    end
    def to_s
        "syntax error on line #{@line}: #{@error_message}"
    end
end
def parse code, show_tokens=false
    @tokens = Lexer.new.tokenize code
    puts @tokens.inspect if show_tokens
    begin
        do_parse
    rescue ParseError => e
        message = e.message.gsub(/parse error on value on line \d+ /, "").gsub("\n","").gsub(/\|\|\|.*/, "")
        line = e.message.gsub(/parse error on value on line /, "").to_i
        raise SyntaxError.new(line, message)
    end
end

def next_token
    @tokens.shift
end
