require_relative "../lib/parser/parser.rb"
require_relative "../lib/utils.rb"

describe "lexer" do
    def parse relative_path, show_tokens = false
        absolute_path = __dir__ + "/data/incorrect/#{relative_path}"
        content = read_file absolute_path
        Parser.new.parse content, show_tokens
    end
    it "parser/pe01.c" do
        # puts ast_to_string parse("parser/p08.c", true).inspect
        expect { parse("parser/pe01.c").inspect }.to raise_error Parser::SyntaxError
    end
end
