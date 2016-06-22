require_relative "../lib/lexer/lexer.rb"
require_relative "../lib/utils.rb"

describe "lexer" do
    def tokenize relative_path
        absolute_path = __dir__ + "/data/quiet/lexer/#{relative_path}"
        content = read_file absolute_path
        Lexer.new.tokenize content
    end
    it "quiet/l01.c" do
        expect(tokenize("l01.c")).to eq  [[:INT, "int"], [:IDENTIFIER, "main"], ["(", "("], [:VOID, "void"], [")", ")"], ["{", "{"], [";", ";"], ["}", "}"]]
    end
    it "quiet/l02.c" do
        expect(tokenize("l02.c")).to eq [[:INT, "int"], [:IDENTIFIER, "foo"], [";", ";"], [:INT, "int"], [:IDENTIFIER, "BarBara"], [";", ";"], [:INT, "int"], [:IDENTIFIER, "bar_bara"], [";", ";"], [:INT, "int"], [:IDENTIFIER, "bar4711"], [";", ";"], [:INT, "int"], [:IDENTIFIER, "b4rb4r4"], [";", ";"], [:INT, "int"], [:IDENTIFIER, "abcdefghijklmnopqrstuvwxyz_ABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789"], [";", ";"], [:INT, "int"], [:IDENTIFIER, "main"], ["(", "("], [:VOID, "void"], [")", ")"], ["{", "{"], [";", ";"], ["}", "}"]]
    end
    it "quiet/l03.c" do
        expect(tokenize("l03.c")).to eq [[:INT, "int"], [:IDENTIFIER, "main"], ["(", "("], [:VOID, "void"], [")", ")"], ["{", "{"], [:INT, "int"], [:IDENTIFIER, "i"], [";", ";"], [:IDENTIFIER, "i"], ["=", "="], [:INT_LITERAL, 123456789], [";", ";"], [:IDENTIFIER, "i"], ["=", "="], [:CHAR_LITERAL, "0"], [";", ";"], [:IDENTIFIER, "i"], ["=", "="], [:CHAR_LITERAL, "a"], [";", ";"], [:IDENTIFIER, "i"], ["=", "="], [:CHAR_LITERAL, " "], [";", ";"], [:IDENTIFIER, "i"], ["=", "="], [:CHAR_LITERAL, "\n"], [";", ";"], ["}", "}"]]
    end
    it "quiet/l04.c" do
        expect(tokenize("l04.c")).to eq [[:INT, "int"], [:IDENTIFIER, "main"], ["(", "("], [:VOID, "void"], [")", ")"], ["{", "{"], [:INT, "int"], [:IDENTIFIER, "i"], [";", ";"], [:CHAR, "char"], [:IDENTIFIER, "j"], [";", ";"], [:IF, "if"], ["(", "("], [:INT_LITERAL, 1], ["==", "=="], [:INT_LITERAL, 0], [")", ")"], [:IDENTIFIER, "i"], ["=", "="], [:INT_LITERAL, 0], [";", ";"], [:ELSE, "else"], [:IDENTIFIER, "i"], ["=", "="], [:INT_LITERAL, 1], [";", ";"], [:WHILE, "while"], ["(", "("], [:INT_LITERAL, 1], ["==", "=="], [:INT_LITERAL, 0], [")", ")"], [:IDENTIFIER, "i"], ["=", "="], [:INT_LITERAL, 0], [";", ";"], [:RETURN, "return"], [:INT_LITERAL, 42], [";", ";"], ["}", "}"]]
    end
    it "quiet/l05.c" do
        expect(tokenize("l05.c")).to eq [[:INT, "int"], [:IDENTIFIER, "main"], ["(", "("], [:VOID, "void"], [")", ")"], ["{", "{"], [:INT, "int"], [:IDENTIFIER, "i"], [";", ";"], [:INT_LITERAL, 1], ["!=", "!="], ["!", "!"], [:INT_LITERAL, 3], [";", ";"], [:INT_LITERAL, 4], ["&&", "&&"], ["(", "("], [:INT_LITERAL, 6], [")", ")"], [";", ";"], [:INT_LITERAL, 7], ["*", "*"], [:INT_LITERAL, 8], ["+", "+"], [:INT_LITERAL, 10], [";", ";"], ["(", "("], [:INT_LITERAL, 11], ["-", "-"], [:INT_LITERAL, 12], [")", ")"], ["+", "+"], ["(", "("], [:INT_LITERAL, 12], ["/", "/"], [:INT_LITERAL, 16], [")", ")"], [";", ";"], [:INT_LITERAL, 17], ["<=", "<="], [:INT_LITERAL, 18], ["<", "<"], ["-", "-"], [:INT_LITERAL, 20], [";", ";"], [:IDENTIFIER, "i"], ["=", "="], [:INT_LITERAL, 21], ["==", "=="], [:INT_LITERAL, 22], [";", ";"], [:INT_LITERAL, 25], [">=", ">="], [:INT_LITERAL, 27], [">", ">"], [:INT_LITERAL, 28], [";", ";"], [:RETURN, "return"], [:INT_LITERAL, 0], [";", ";"], ["}", "}"]]


    end
    it "quiet/l06.c" do
        expect(tokenize("l06.c")).to eq [[:INT, "int"], [:IDENTIFIER, "main"], ["(", "("], [:VOID, "void"], [")", ")"], ["{", "{"], [";", ";"], ["}", "}"]]
    end
end

