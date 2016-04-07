class Parser
# ---- [precedance table] ----------------------------------------------
prechigh
# Prefix unary operators
nonassoc "-" "!" # 14R?
# Infix operators
left "*" "/" # 13L
left "+" "-" # 12L
left "<" ">" "<=" ">=" # 10L
left "==" "!=" #9L
left "&&" # 5L
right "=" # 2R
preclow

# ---- [token declearations] -------------------------------------------
token IDENTIFIER KEYWORD OPERATOR
token CHAR ELSE IF INT RETURN VOID WHILE
token INT_LITERAL CHAR_LITERAL
# ---- [expected number of S/R conflict] -------------------------------
# ---- [options] -------------------------------------------------------
# ---- [semantic value convertion] -------------------------------------
# ---- [start rule] ----------------------------------------------------
start program
# ---- [grammar] -------------------------------------------------------
rule
    program : /* empty program */
            | topdec_list

    topdec_list : /* empty */
                | topdec topdec_list

    topdec : vardec ";"
           | funtype IDENTIFIER "(" formals ")" funbody

    vardec : scalardec
           | arraydec

    scalardec : typename IDENTIFIER
    arraydec  : typename IDENTIFIER "[" INT_LITERAL "]"

    typename : INT
             | CHAR

    funtype : typename | VOID
    funbody : "{" locals stmts "}" | ";"

    formals : VOID | formal_list

    formal_list : formaldec
                | formaldec "," formal_list

    formaldec : scalardec
              | typename IDENTIFIER "[" "]"

    locals : /* empty */
           | vardec ";" locals

    stmts : /* empty */
          | stmt stmts


    stmt : expr ";"
         | RETURN expr ";" | RETURN ";"
         | WHILE condition stmt
         | IF condition stmt else_part
         | "{" stmts "}"
         | ";"

    else_part : /* empty */ | ELSE stmt
    condition : "(" expr ")"

    expr : INT_LITERAL
         | IDENTIFIER
         | IDENTIFIER "[" expr "]"
         | unop expr
         | expr binop expr
         | IDENTIFIER "(" actuals ")"
         | "(" expr ")"

    unop : "-"
         | "!"
    binop : "+"
          | "-"
          | "*"
          | "/"
          | "<"
          | ">"
          | "<="
          | ">="
          | "!="
          | "=="
          | "&&"
          | "="

    actuals : /* empty */
            | expr_list

    expr_list : expr
              | expr "," expr_list

end
# ---- [header] --------------------------------------------------------
---- header
require_relative "../lexer/lexer.rb"

# ---- [inner] ---------------------------------------------------------
---- inner
def parse code, show_tokens=false
    @tokens = Lexer.new.tokenize code
    puts @tokens.inspect if show_tokens
    do_parse
end

def next_token
    @tokens.shift
end
