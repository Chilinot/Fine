require_relative "../lib/parser/parser.rb"
require_relative "../lib/semantic/semantic_analysis.rb"
require_relative "../lib/ir/ir.rb"
require_relative "../lib/code/code_generation.rb"

describe "ir" do
    it "generates llvm" do
        data = {
"int foo;" => "@foo = global i32 zeroinitializer",
"char foo;" => "@foo = global i8 zeroinitializer",
"int foo[42];" => "@foo = global [42 x i32] zeroinitializer",
"char foo[42];" => "@foo = global [42 x i8] zeroinitializer",
#-------------------------------------------------------------------
"int main(void) { return 0; }" =>
"
define i32 @main() {
    ret i32 0
}
"
        }
        data.each do |uc, llvm|
            expect(uc_to_llvm(uc)).to eq llvm.strip
        end
    end

    def uc_to_llvm string
        begin
            ast = Parser.new.parse string
            if semantic_analysis(ast)
                ir = generate_ir ast
                return generate_llvm ir
            end
        rescue Lexer::LexicalError => e
            puts e
        rescue Parser::SyntaxError => e
            puts e
        rescue SemanticError => e
            puts e
        end
    end
end
