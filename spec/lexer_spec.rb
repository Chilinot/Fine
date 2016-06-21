require_relative "../lib/lexer/lexer.rb"

describe "lexer" do
    def tokenize_error_message string, show_tokens = false
        begin
            Lexer.new.tokenize string, show_tokens
        rescue Lexer::LexicalError => e
            e.to_s
        end
    end
    it "tokenizes non-negative integers" do
        expect(Lexer.new.tokenize("1 2 42 0 001")).to eq [[:INT_LITERAL, 1],
                                                          [:INT_LITERAL, 2],
                                                          [:INT_LITERAL, 42],
                                                          [:INT_LITERAL, 0],
                                                          [:INT_LITERAL, 1]]
    end
    it "tokenizes character literals" do
        expect(Lexer.new.tokenize("'a' '1' '\\n'")).to eq [[:CHAR_LITERAL, "a"], [:CHAR_LITERAL, "1"], [:CHAR_LITERAL, "\n"]]
    end
    it "handles incorrect character literals" do
        expect(tokenize_error_message("'foo'")).to eq "Lexical error on line 1: invalid token |'foo'|"
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
        expect(tokenize_error_message("42foo")).to eq "Lexical error on line 1: invalid token |42foo|"
    end
    it "tokenizes identifiers starting with keywords" do
        expect(Lexer.new.tokenize("charelse ifint returnvoidwhile iff")).to eq [[:IDENTIFIER, "charelse"],
                                                                                [:IDENTIFIER, "ifint"],
                                                                                [:IDENTIFIER, "returnvoidwhile"],
                                                                                [:IDENTIFIER, "iff"]]
    end

    it "tokenizes keywords" do
        expect(Lexer.new.tokenize("char else if int return void while")).to eq [[:CHAR, "char"],
                                                                                [:ELSE, "else"],
                                                                                [:IF, "if"],
                                                                                [:INT, "int"],
                                                                                [:RETURN, "return"],
                                                                                [:VOID, "void"],
                                                                                [:WHILE, "while"]]
    end

    it "tokenizes operators" do
        expect(Lexer.new.tokenize("+-*/<><=>===!=&&||=!")).to eq [["+", "+"],
                                                                  ["-", "-"],
                                                                  ["*", "*"],
                                                                  ["/", "/"],
                                                                  ["<", "<"],
                                                                  [">", ">"],
                                                                  ["<=", "<="],
                                                                  [">=", ">="],
                                                                  ["==", "=="],
                                                                  ["!=", "!="],
                                                                  ["&&", "&&"],
                                                                  ["||", "||"],
                                                                  ["=", "="],
                                                                  ["!", "!"]]
    end
    it "tokenizes delimiter" do
        expect(Lexer.new.tokenize("()[]{},;")).to eq [["(", "("],
                                                      [")", ")"],
                                                      ["[", "["],
                                                      ["]", "]"],
                                                      ["{", "{"],
                                                      ["}", "}"],
                                                      [",", ","],
                                                      [";", ";"]]
    end
    it "ignores multi-line comments" do
        expect(Lexer.new.tokenize("int foo; /* this is a multi-line comment with newlines \n and tabs \t */ c + +")).to eq [[:INT, "int"],
                                                                                                                            [:IDENTIFIER, "foo"],
                                                                                                                            [";", ";"],
                                                                                                                            [:IDENTIFIER, "c"],
                                                                                                                            ["+", "+"],
                                                                                                                            ["+", "+"]]
    end

    it "handles invalid tokens" do
        expect(tokenize_error_message("int a;\n/*\n  this is a comment\n\n*/int 42foo;")).to eq "Lexical error on line 5: invalid token |42foo|"
    end

    it "handles unclosed multi-line comments" do
        expect(tokenize_error_message("/* this is an unclosed multi-line comment")).to eq "Lexical error on line 1: unclosed comment |/* this is an unclosed multi-line comment|"
        expect(tokenize_error_message("int a;\n //this is \n/* this is an unclosed multi-line comment")).to eq "Lexical error on line 3: unclosed comment |/* this is an unclosed multi-line comment|"
    end

    it "handles comments that do not end with newline" do
        expect(Lexer.new.tokenize("// this is a comment")).to eq []
    end

    it "throws general error on unrecognized tokens" do
        expect(tokenize_error_message("^")).to eq "Lexical error on line 1: unrecognized token |^|"
    end
end
