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
end
