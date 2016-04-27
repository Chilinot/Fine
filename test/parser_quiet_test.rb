require_relative "../lib/parser/parser.rb"
require_relative "../lib/utils.rb"

describe "lexer" do
    def parse relative_path, show_tokens = false
        absolute_path = __dir__ + "/data/quiet/#{relative_path}"
        content = read_file absolute_path
        Parser.new.parse content, show_tokens
    end
    it "lexer/l05.c" do
        expect(parse("lexer/l05.c").inspect).to eq "#<struct Program nodes=[#<struct FunctionDeclaration type=:INT, name=\"main\", formals=[], body=#<struct FunctionBody declarations=[#<struct VarDeclaration type=:INT, name=\"i\">], statments=[#<struct NotEqualNode left=#<struct Constant type=:INT, value=1>, right=#<struct Not expr=#<struct Constant type=:INT, value=3>>>, #<struct AndNode left=#<struct Constant type=:INT, value=4>, right=#<struct Constant type=:INT, value=6>>, #<struct AddNode left=#<struct MulNode left=#<struct Constant type=:INT, value=7>, right=#<struct Constant type=:INT, value=8>>, right=#<struct Constant type=:INT, value=10>>, #<struct AddNode left=#<struct SubNode left=#<struct Constant type=:INT, value=11>, right=#<struct Constant type=:INT, value=12>>, right=#<struct DivNode left=#<struct Constant type=:INT, value=12>, right=#<struct Constant type=:INT, value=16>>>, #<struct LessThanNode left=#<struct LessEqualNode left=#<struct Constant type=:INT, value=17>, right=#<struct Constant type=:INT, value=18>>, right=#<struct UnaryMinus expr=#<struct Constant type=:INT, value=20>>>, #<struct AssignNode left=#<struct Identifier name=\"i\">, right=#<struct EqualNode left=#<struct Constant type=:INT, value=21>, right=#<struct Constant type=:INT, value=22>>>, #<struct GreaterThanNode left=#<struct GreaterEqualNode left=#<struct Constant type=:INT, value=25>, right=#<struct Constant type=:INT, value=27>>, right=#<struct Constant type=:INT, value=28>>]>>]>"
    end
    it "parser/p01.c" do
        expect(parse("parser/p01.c").inspect).to eq "#<struct Program nodes=[#<struct FunctionDeclaration type=:INT, name=\"main\", formals=[], body=#<struct FunctionBody declarations=[#<struct VarDeclaration type=:INT, name=\"x\">, #<struct VarDeclaration type=:INT, name=\"y\">], statments=[#<struct AssignNode left=#<struct Identifier name=\"x\">, right=#<struct Constant type=:INT, value=42>>, #<struct AssignNode left=#<struct Identifier name=\"x\">, right=#<struct AssignNode left=#<struct Identifier name=\"y\">, right=#<struct Constant type=:INT, value=4711>>>]>>]>"
    end
    it "parser/p02.c" do
        expect(parse("parser/p02.c").inspect).to eq "#<struct Program nodes=[#<struct FunctionDeclaration type=:INT, name=\"main\", formals=[], body=#<struct FunctionBody declarations=[#<struct VarDeclaration type=:INT, name=\"x\">], statments=[#<struct While condition=#<struct LessThanNode left=#<struct Identifier name=\"x\">, right=#<struct Constant type=:INT, value=10>>, block=[#<struct AssignNode left=#<struct Identifier name=\"x\">, right=#<struct AddNode left=#<struct Identifier name=\"x\">, right=#<struct Constant type=:INT, value=3>>>]>, #<struct If condition=#<struct Constant type=:INT, value=1>, then_block=[#<struct AssignNode left=#<struct Identifier name=\"x\">, right=#<struct AddNode left=#<struct Identifier name=\"x\">, right=#<struct Constant type=:INT, value=3>>>], else_block=nil>]>>]>"

    end
    it "parser/p03.c" do
        expect(parse("parser/p03.c").inspect).to eq "#<struct Program nodes=[#<struct FunctionDeclaration type=:INT, name=\"main\", formals=[], body=#<struct FunctionBody declarations=[#<struct VarDeclaration type=:INT, name=\"x\">], statments=[#<struct If condition=#<struct LessThanNode left=#<struct Constant type=:INT, value=1>, right=#<struct Constant type=:INT, value=2>>, then_block=[#<struct AssignNode left=#<struct Identifier name=\"x\">, right=#<struct Constant type=:INT, value=1>>], else_block=[#<struct AssignNode left=#<struct Identifier name=\"x\">, right=#<struct Constant type=:INT, value=2>>]>]>>]>"

    end
    it "parser/p04.c" do
        expect(parse("parser/p04.c").inspect).to eq "#<struct Program nodes=[#<struct FunctionDeclaration type=:INT, name=\"main\", formals=[], body=#<struct FunctionBody declarations=[#<struct VarDeclaration type=:INT, name=\"x\">, #<struct VarDeclaration type=:INT, name=\"y\">, #<struct VarDeclaration type=:INT, name=\"z\">], statments=[#<struct SubNode left=#<struct SubNode left=#<struct SubNode left=#<struct Identifier name=\"x\">, right=#<struct Identifier name=\"y\">>, right=#<struct Identifier name=\"z\">>, right=#<struct Constant type=:INT, value=42>>, #<struct NotEqualNode left=#<struct LessThanNode left=#<struct AddNode left=#<struct MulNode left=#<struct Not expr=#<struct Identifier name=\"x\">>, right=#<struct Identifier name=\"y\">>, right=#<struct Identifier name=\"z\">>, right=#<struct Identifier name=\"x\">>, right=#<struct LessThanNode left=#<struct Constant type=:INT, value=42>, right=#<struct AddNode left=#<struct Identifier name=\"x\">, right=#<struct MulNode left=#<struct Identifier name=\"y\">, right=#<struct Not expr=#<struct Identifier name=\"x\">>>>>>]>>]>"

    end
    it "parser/p05.c" do
        expect(parse("parser/p05.c").inspect).to eq "#<struct Program nodes=[#<struct ArrayDeclaration type=:INT, name=\"c\", num_elements=10>, #<struct ArrayDeclaration type=:CHAR, name=\"d\", num_elements=10>, #<struct FunctionDeclaration type=:VOID, name=\"f\", formals=[#<struct ArrayDeclaration type=:INT, name=\"h\", num_elements=nil>, #<struct ArrayDeclaration type=:CHAR, name=\"i\", num_elements=nil>], body=#<struct FunctionBody declarations=[], statments=[]>>, #<struct FunctionDeclaration type=:INT, name=\"main\", formals=[], body=#<struct FunctionBody declarations=[], statments=[]>>]>"

    end
    it "parser/p06.c" do
        expect(parse("parser/p06.c").inspect).to eq "#<struct Program nodes=[#<struct FunctionDeclaration type=:VOID, name=\"f\", formals=[], body=#<struct FunctionBody declarations=[], statments=[#<struct Return expr=:VOID>]>>, #<struct FunctionDeclaration type=:INT, name=\"g\", formals=[], body=#<struct FunctionBody declarations=[], statments=[#<struct Return expr=#<struct Constant type=:INT, value=42>>]>>, #<struct FunctionDeclaration type=:INT, name=\"main\", formals=[], body=#<struct FunctionBody declarations=[], statments=[#<struct FunctionCall name=\"f\", args=[]>, #<struct FunctionCall name=\"g\", args=[]>]>>]>"
    end
    it "parser/p07.c" do
        expect(parse("parser/p07.c").inspect).to eq "#<struct Program nodes=[#<struct FunctionDeclaration type=:INT, name=\"main\", formals=[], body=#<struct FunctionBody declarations=[#<struct VarDeclaration type=:INT, name=\"x\">, #<struct VarDeclaration type=:INT, name=\"y\">], statments=[#<struct If condition=#<struct Identifier name=\"x\">, then_block=[#<struct While condition=#<struct Identifier name=\"y\">, block=[#<struct AssignNode left=#<struct Identifier name=\"x\">, right=#<struct Constant type=:INT, value=42>>]>], else_block=nil>, #<struct While condition=#<struct Identifier name=\"x\">, block=[#<struct If condition=#<struct Identifier name=\"y\">, then_block=[#<struct AssignNode left=#<struct Identifier name=\"x\">, right=#<struct Constant type=:INT, value=42>>], else_block=nil>]>]>>]>"

    end
    it "parser/p08.c" do
        # puts ast_to_string parse("parser/p08.c", true).inspect
        expect(parse("parser/p08.c").inspect).to eq "#<struct Program nodes=[#<struct FunctionDeclaration type=:INT, name=\"main\", formals=[], body=#<struct FunctionBody declarations=[#<struct VarDeclaration type=:INT, name=\"x\">, #<struct VarDeclaration type=:INT, name=\"y\">], statments=[#<struct If condition=#<struct Identifier name=\"x\">, then_block=[#<struct If condition=#<struct Identifier name=\"y\">, then_block=[#<struct AssignNode left=#<struct Identifier name=\"x\">, right=#<struct Constant type=:INT, value=4711>>], else_block=[#<struct AssignNode left=#<struct Identifier name=\"x\">, right=#<struct Constant type=:INT, value=42>>]>], else_block=nil>]>>]>"
    end
end
