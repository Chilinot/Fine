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
        exit
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
end
