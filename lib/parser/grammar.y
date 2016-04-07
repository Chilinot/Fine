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
# expect 1
# ---- [options] -------------------------------------------------------
# ---- [semantic value convertion] -------------------------------------
# ---- [start rule] ----------------------------------------------------
start program
# ---- [grammar] -------------------------------------------------------
rule

    program : topdec_list

    topdec_list : /* empty */
                | topdec topdec_list

    topdec : typename IDENTIFIER "(" formals ")" funbody
           | vardec ";"

    vardec : scalardec
           | arraydec

    scalardec : typename IDENTIFIER
    arraydec  : typename IDENTIFIER "[" INT_LITERAL "]"

    typename : INT
             | CHAR
             | VOID

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
         | WHILE condition block
         | IF condition block ELSE block
         | IF condition block
         | block
         | ";"

    block : "{" stmts "}"

    condition : "(" expr ")"

    expr : INT_LITERAL
         | IDENTIFIER
         | IDENTIFIER "[" expr "]"
         | "-" expr
         | "!" expr
         | expr "+" expr
         | expr "-" expr
         | expr "*" expr
         | expr "/" expr
         | expr "<" expr
         | expr ">" expr
         | expr "<=" expr
         | expr ">=" expr
         | expr "!=" expr
         | expr "==" expr
         | expr "&&" expr
         | expr "=" expr
         | IDENTIFIER "(" actuals ")"
         | "(" expr ")"

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
