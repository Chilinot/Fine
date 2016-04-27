require_relative "../lib/semantic/semantic_analysis.rb"
require_relative "../lib/parser/parser.rb"
require_relative "../lib/utils.rb"

describe "semantic_analysis" do
    def check_semantics relative_path, show_tokens = false
        absolute_path = __dir__ + "/data/incorrect/#{relative_path}"
        content = read_file absolute_path
        semantic_analysis( Parser.new.parse content, show_tokens)
    end
    def check file
        begin
            check_semantics file
        rescue SemanticError => e
            return e.message
        end
    end
    it "semantic/se01.c" do
        expect(check("semantic/se01.c")).to eq "Semantic error: b was not defined"
    end
    it "semantic/se02.c" do
        expect(check("semantic/se02.c")).to eq "Semantic error: foo was not defined"
    end
    it "semantic/se03.c" do
        expect(check("semantic/se03.c")).to eq "Semantic error: output was not defined"
    end
    it "semantic/se04.c" do
        expect(check("semantic/se04.c")).to eq "Semantic error: a already defined"
    end
    it "semantic/se05.c" do
        expect(check("semantic/se05.c")).to eq "Semantic error: a already defined"
    end
    it "semantic/se06.c" do
        expect(check("semantic/se06.c")).to eq "Semantic error: a already defined"
    end
    it "semantic/se07.c" do
        expect(check("semantic/se07.c")).to eq "Semantic error: attempt to return value from procedure"
    end
    it "semantic/se08.c" do
        expect(check("semantic/se08.c")).to eq "Semantic error: void return from function"
    end
    it "semantic/se09.c" do
        expect(check("semantic/se09.c")).to eq "Semantic error: expression does not match return type"
    end
    it "semantic/se10.c" do
        expect(check("semantic/se10.c")).to eq "Semantic error: n is not an array"
    end
    it "semantic/se11.c" do
        expect(check("semantic/se11.c")).to eq "Semantic error: can not assign to function"
    end
    it "semantic/se12.c" do
        expect(check("semantic/se12.c")).to eq "Semantic error: a is not a function or procedure"
    end
    it "semantic/se13.c" do
        expect(check("semantic/se13.c")).to eq "Semantic error: int + void is not defined"
    end
    it "semantic/se14.c" do
        expect(check("semantic/se14.c")).to eq  "Semantic error: f is not a function or procedure"
    end
    it "semantic/se15.c" do
        expect(check("semantic/se15.c")).to eq "Semantic error: q expected 3 arguments, but got 2"
    end
    it "semantic/se15_wrong_argument_types.c" do
        expect(check("semantic/se15_wrong_argument_types.c")).to eq "Semantic error: q expected argument at position 2 to be of type int, but got type char"
    end
end
