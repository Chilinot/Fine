require_relative "../source/lexer/lexer.rb"

describe "lexer" do
    it "tokenizes non-negative integers" do
        expect(Lexer.new.tokenize("1 2 42 0 001")).to eq [[:INT, 1], [:INT, 2], [:INT, 42], [:INT, 0], [:INT, 1]]
    end
    it "tokenizes identifiers" do
        expect(Lexer.new.tokenize("a b _ foo foo123 foo_bar _42")).to eq [[:ID, "a"], [:ID, "b"], [:ID, "_"], [:ID, "foo"], [:ID, "foo123"], [:ID, "foo_bar"], [:ID, "_42"]]
    end
    it "handles incorrect identifiers" do
        expect {Lexer.new.tokenize("42foo") }.to raise_error(Lexer::LexicalError)
    end
end
