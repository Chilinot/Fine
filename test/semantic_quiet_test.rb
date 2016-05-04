require_relative "../lib/semantic/semantic_analysis.rb"
require_relative "../lib/parser/parser.rb"
require_relative "../lib/utils.rb"

describe "semantic analysis" do
    def check_semantics relative_path, show_tokens = false
        absolute_path = __dir__ + "/data/quiet/#{relative_path}"
        content = read_file absolute_path
        semantic_analysis( Parser.new.parse content, show_tokens)
    end
    it "semantic/s01.c" do
        expect(check_semantics("semantic/s01.c")).to true
    end
end
