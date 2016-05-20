require_relative "../lib/parser/parser.rb"
require_relative "../lib/semantic/semantic_analysis.rb"
require_relative "../lib/ir/ir.rb"
# require_relative "../lib/utils.rb"


describe "ir" do
    def string_to_ast string
        begin
            ast = Parser.new.parse string
            if semantic_analysis(ast)
                return ast
            end
        rescue Lexer::LexicalError => e
            puts e
        rescue Parser::SyntaxError => e
            puts e
        rescue SemanticError => e
            puts e
        end
    end

    it "handles empty programs" do
        expect(generate_ir (string_to_ast "")).to eq Ir.new []
    end
    it "handle global int variables" do
        expect(generate_ir (string_to_ast "int foo;")).to eq Ir.new [GlobalInt.new("foo")]
    end
    it "handle global char variables" do
        expect(generate_ir (string_to_ast "char foo;")).to eq Ir.new [GlobalChar.new("foo")]
    end
    it "handle global int arrays" do
        expect(generate_ir (string_to_ast "int foo[42];")).to eq Ir.new [GlobalIntArray.new("foo",42)]
    end
    it "handle global char arrays" do
        expect(generate_ir (string_to_ast "char foo[42];")).to eq Ir.new [GlobalCharArray.new("foo",42)]
    end
    it "handle global int and char array" do
        expect(generate_ir (string_to_ast "int foo; char bar[2];")).to eq Ir.new [GlobalInt.new("foo"),GlobalCharArray.new("bar",2)]
    end
    it "ignores extern declaration" do
        expect(generate_ir (string_to_ast "void main(void);")).to eq Ir.new []
    end
    it "handles simple function declaration" do
        expect(generate_ir (string_to_ast "void main(void) {}")).to eq Ir.new [ Function.new("main",:VOID, [],[],[]) ]
    end
    it "handles functions with formals" do
        expect(generate_ir (string_to_ast "void f(int a, int b) {  }")).to eq Ir.new [ Function.new("f",:VOID, [{:type => :INT, :name => "a"},
                                                                                                                {:type => :INT, :name => "b"}],[],[]) ]
    end
    it "handles functions with explicit empty return" do
        expect(generate_ir (string_to_ast "void main(void) { return; }")).to eq Ir.new [ Function.new("main",:VOID, [],[],[Return.new(:VOID)]) ]
    end
    it "handles functions with local char" do
        expect(generate_ir (string_to_ast "void main(void) { int foo; }")).to eq Ir.new [ Function.new("main",:VOID, [],[LocalInt.new("foo")],[]) ]
    end
    it "handles functions with local int" do
        expect(generate_ir (string_to_ast "void main(void) { char foo; }")).to eq Ir.new [ Function.new("main",:VOID, [],[LocalChar.new("foo")],[]) ]
    end
    it "handles functions with multiple local variables" do
        expect(generate_ir (string_to_ast "void main(void) { int foo; char bar; }")).to eq Ir.new [ Function.new("main",:VOID, [],[LocalInt.new("foo"), LocalChar.new("bar")],[]) ]
    end
    it "handles functions with local int-array" do
        expect(generate_ir (string_to_ast "void main(void) { int foo[42]; }")).to eq Ir.new [ Function.new("main",:VOID, [],[LocalIntArray.new("foo", 42)],[]) ]
    end
    it "handles functions with local char-array" do
        expect(generate_ir (string_to_ast "void main(void) { char foo[22]; }")).to eq Ir.new [ Function.new("main",:VOID, [],[LocalCharArray.new("foo",22)],[]) ]
    end
    it "handles functions returning a int constant" do
        expect(generate_ir (string_to_ast "int main(void) { return 42; }")).to eq Ir.new [ Function.new("main",:INT, [],[],[Return.new(Constant.new(42))]) ]
    end
    it "handles functions returning a char constant" do
        expect(generate_ir (string_to_ast "char main(void) { return 'a'; }")).to eq Ir.new [ Function.new("main",:CHAR, [],[],[Return.new(Constant.new(97))]) ]
    end
    it "handles functions returning a 1 + 2" do
        expect(generate_ir (string_to_ast "int main(void) { return 'a'; }")).to eq Ir.new [ Function.new("main",:INT, [],[],
            [
                Add.new(Temporary.new(1), Constant.new(1), Constant.new(2)),
                Return.new(Temporary.new(1))
            ]
        )]
    end
end
