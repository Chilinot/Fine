require_relative "../lib/lexer/lexer.rb"
require_relative "../lib/utils.rb"

describe "lexer" do
    def tokenize relative_path
        absolute_path = __dir__ + "/data/#{relative_path}"
        content = read_file absolute_path
        Lexer.new.tokenize content
    end
    it "incorrect/long-char.c" do
        expect {tokenize("incorrect/lexer/long-char.c")}.to raise_error(Lexer::LexicalError)
    end
    it "incorrect/ugly.c" do
        expect {tokenize("incorrect/lexer/ugly.c")}.to raise_error(EncodingError)
    end
    it "incorrect/bad.c" do
        expect {tokenize("incorrect/lexer/bad.c")}.to raise_error(Lexer::LexicalError)
    end
end

