require_relative "../lib/lexer/lexer.rb"

describe "lexer" do
    it "tokenizes non-negative integers" do
        expect(Lexer.new.tokenize("1 2 42 0 001")).to eq [[:INT, 1], [:INT, 2], [:INT, 42], [:INT, 0], [:INT, 1]]
    end
    it "tokenizes character literals" do
        expect(Lexer.new.tokenize("'a' '1' '\\n'")).to eq [[:CHAR, "a"], [:CHAR, "1"], [:CHAR, "\\n"]]
    end
    it "handles incorrect character literals" do
        expect {Lexer.new.tokenize("'foo'") }.to raise_error(Lexer::LexicalError)
    end

    it "tokenizes identifiers" do
        expect(Lexer.new.tokenize("a b _ foo foo123 foo_bar _42")).to eq [[:IDENTIFIER, "a"],
                                                                          [:IDENTIFIER, "b"],
                                                                          [:IDENTIFIER, "_"],
                                                                          [:IDENTIFIER, "foo"],
                                                                          [:IDENTIFIER, "foo123"],
                                                                          [:IDENTIFIER, "foo_bar"],
                                                                          [:IDENTIFIER, "_42"]]
    end
    it "handles incorrect identifiers" do
        expect {Lexer.new.tokenize("42foo") }.to raise_error(Lexer::LexicalError)
    end
    it "tokenizes identifiers starting with keywords" do
        expect(Lexer.new.tokenize("charelse ifint returnvoidwhile iff")).to eq [[:IDENTIFIER, "charelse"],
                                                                                [:IDENTIFIER, "ifint"],
                                                                                [:IDENTIFIER, "returnvoidwhile"],
                                                                                [:IDENTIFIER, "iff"]]
    end

    it "tokenizes keywords" do
        expect(Lexer.new.tokenize("char else if int return void while")).to eq [[:KEYWORD, :char],
                                                                                [:KEYWORD, :else],
                                                                                [:KEYWORD, :if],
                                                                                [:KEYWORD, :int],
                                                                                [:KEYWORD, :return],
                                                                                [:KEYWORD, :void],
                                                                                [:KEYWORD, :while]]
    end

    it "tokenizes operators" do
        expect(Lexer.new.tokenize("+-*/<><=>===!=&&||=!")).to eq [[:OPERATOR, "+"],
                                                                               [:OPERATOR, "-"],
                                                                               [:OPERATOR, "*"],
                                                                               [:OPERATOR, "/"],
                                                                               [:OPERATOR, "<"],
                                                                               [:OPERATOR, ">"],
                                                                               [:OPERATOR, "<="],
                                                                               [:OPERATOR, ">="],
                                                                               [:OPERATOR, "=="],
                                                                               [:OPERATOR, "!="],
                                                                               [:OPERATOR, "&&"],
                                                                               [:OPERATOR, "||"],
                                                                               [:OPERATOR, "="],
                                                                               [:OPERATOR, "!"]]
    end
    it "tokenizes delimiter" do
        expect(Lexer.new.tokenize("()[]{},;")).to eq [[:DELIMITER, "("],
                                                              [:DELIMITER, ")"],
                                                              [:DELIMITER, "["],
                                                              [:DELIMITER, "]"],
                                                              [:DELIMITER, "{"],
                                                              [:DELIMITER, "}"],
                                                              [:DELIMITER, ","],
                                                              [:DELIMITER, ";"]]
    end
    it "handles invalid tokens" do
        expect {Lexer.new.tokenize("int a;\n/*\n  this is a comment\n\n*/int 42foo;") }.to raise_error(Lexer::LexicalError)
    end

    it "handles unclosed multi-line comments" do
        expect {Lexer.new.tokenize("/* this is an unclosed multi-line comment", true) }.to raise_error(Lexer::LexicalError)
        expect {Lexer.new.tokenize("int a;\n //this is \n/* this is an unclosed multi-line comment", true) }.to raise_error(Lexer::LexicalError)
    end

    it "handles comments that do not end with newline" do
        expect(Lexer.new.tokenize("// this is a comment")).to eq []
    end
end