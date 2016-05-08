require_relative "../lib/semantic/semantic_analysis.rb"
require_relative "../lib/parser/parser.rb"
require_relative "../lib/utils.rb"

describe "semantic analysis" do
    def check_semantics relative_path, show_tokens = false
        absolute_path = __dir__ + "/data/quiet/#{relative_path}"
        content = read_file absolute_path
        semantic_analysis( Parser.new.parse content, show_tokens)
    end
    it "semantic/s00.c" do
        expect(check_semantics("semantic/s00.c")).to eq true
    end
    it "semantic/s01.c" do
        expect(check_semantics("semantic/s01.c")).to eq true
    end
    it "semantic/s02.c" do
        expect(check_semantics("semantic/s02.c")).to eq true
    end
    it "semantic/s03.c" do
        expect(check_semantics("semantic/s03.c")).to eq true
    end
    it "semantic/s04.c" do
        expect(check_semantics("semantic/s04.c")).to eq true
    end
    it "semantic/s05.c" do
        expect(check_semantics("semantic/s05.c")).to eq true
    end
    it "semantic/s06.c" do
        expect(check_semantics("semantic/s06.c")).to eq true
    end
    it "semantic/s07.c" do
        expect(check_semantics("semantic/s07.c")).to eq true
    end
end
