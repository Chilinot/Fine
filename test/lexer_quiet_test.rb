require_relative "../lib/lexer/lexer.rb"
require_relative "../lib/utils.rb"

describe "lexer" do
    def tokenize relative_path
        absolute_path = __dir__ + "/data/#{relative_path}"
        content = read_file absolute_path
        Lexer.new.tokenize content
    end
    it "quiet/l01.c" do
        expect(tokenize("quiet/lexer/l01.c")).to eq [[:KEYWORD, :int], [:IDENTIFIER, "main"], [:DELIMITER, "("], [:KEYWORD, :void], [:DELIMITER, ")"], [:DELIMITER, "{"], [:DELIMITER, ";"], [:DELIMITER, "}"]]
    end
    it "quiet/l02.c" do
        expect(tokenize("quiet/lexer/l02.c")).to eq [[:KEYWORD, :int], [:IDENTIFIER, "foo"], [:DELIMITER, ";"], [:KEYWORD, :int], [:IDENTIFIER, "BarBara"], [:DELIMITER, ";"], [:KEYWORD, :int], [:IDENTIFIER, "bar_bara"], [:DELIMITER, ";"], [:KEYWORD, :int], [:IDENTIFIER, "bar4711"], [:DELIMITER, ";"], [:KEYWORD, :int], [:IDENTIFIER, "b4rb4r4"], [:DELIMITER, ";"], [:KEYWORD, :int], [:IDENTIFIER, "abcdefghijklmnopqrstuvwxyz_ABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789"], [:DELIMITER, ";"], [:KEYWORD, :int], [:IDENTIFIER, "main"], [:DELIMITER, "("], [:KEYWORD, :void], [:DELIMITER, ")"], [:DELIMITER, "{"], [:DELIMITER, ";"], [:DELIMITER, "}"]]
    end
    it "quiet/l03.c" do
        expect(tokenize("quiet/lexer/l03.c")).to eq [[:KEYWORD, :int], [:IDENTIFIER, "main"], [:DELIMITER, "("], [:KEYWORD, :void], [:DELIMITER, ")"], [:DELIMITER, "{"], [:KEYWORD, :int], [:IDENTIFIER, "i"], [:DELIMITER, ";"], [:IDENTIFIER, "i"], [:OPERATOR, "="], [:INT, 123456789], [:DELIMITER, ";"], [:IDENTIFIER, "i"], [:OPERATOR, "="], [:CHAR, "0"], [:DELIMITER, ";"], [:IDENTIFIER, "i"], [:OPERATOR, "="], [:CHAR, "a"], [:DELIMITER, ";"], [:IDENTIFIER, "i"], [:OPERATOR, "="], [:CHAR, " "], [:DELIMITER, ";"], [:IDENTIFIER, "i"], [:OPERATOR, "="], [:CHAR, "\\n"], [:DELIMITER, ";"], [:DELIMITER, "}"]]
    end
    it "quiet/l04.c" do
        expect(tokenize("quiet/lexer/l04.c")).to eq [[:KEYWORD, :int], [:IDENTIFIER, "main"], [:DELIMITER, "("], [:KEYWORD, :void], [:DELIMITER, ")"], [:DELIMITER, "{"], [:KEYWORD, :int], [:IDENTIFIER, "i"], [:DELIMITER, ";"], [:KEYWORD, :char], [:IDENTIFIER, "j"], [:DELIMITER, ";"], [:KEYWORD, :if], [:DELIMITER, "("], [:INT, 1], [:OPERATOR, "=="], [:INT, 0], [:DELIMITER, ")"], [:IDENTIFIER, "i"], [:OPERATOR, "="], [:INT, 0], [:DELIMITER, ";"], [:KEYWORD, :else], [:IDENTIFIER, "i"], [:OPERATOR, "="], [:INT, 1], [:DELIMITER, ";"], [:KEYWORD, :while], [:DELIMITER, "("], [:INT, 1], [:OPERATOR, "=="], [:INT, 0], [:DELIMITER, ")"], [:IDENTIFIER, "i"], [:OPERATOR, "="], [:INT, 0], [:DELIMITER, ";"], [:KEYWORD, :return], [:INT, 42], [:DELIMITER, ";"], [:DELIMITER, "}"]]
    end
    it "quiet/l05.c" do
        expect(tokenize("quiet/lexer/l05.c")).to eq [[:KEYWORD, :int], [:IDENTIFIER, "main"], [:DELIMITER, "("], [:KEYWORD, :void], [:DELIMITER, ")"], [:DELIMITER, "{"], [:KEYWORD, :int], [:IDENTIFIER, "i"], [:DELIMITER, ";"], [:INT, 1], [:OPERATOR, "!="], [:OPERATOR, "!"], [:INT, 3], [:DELIMITER, ";"], [:INT, 4], [:OPERATOR, "&&"], [:DELIMITER, "("], [:INT, 6], [:DELIMITER, ")"], [:DELIMITER, ";"], [:INT, 7], [:OPERATOR, "*"], [:INT, 8], [:OPERATOR, "+"], [:INT, 10], [:DELIMITER, ";"], [:DELIMITER, "("], [:INT, 11], [:OPERATOR, "-"], [:INT, 12], [:DELIMITER, ")"], [:OPERATOR, "+"], [:DELIMITER, "("], [:INT, 12], [:OPERATOR, "/"], [:INT, 16], [:DELIMITER, ")"], [:DELIMITER, ";"], [:INT, 17], [:OPERATOR, "<="], [:INT, 18], [:OPERATOR, "<"], [:OPERATOR, "-"], [:INT, 20], [:DELIMITER, ";"], [:IDENTIFIER, "i"], [:OPERATOR, "="], [:INT, 21], [:OPERATOR, "=="], [:INT, 22], [:DELIMITER, ";"], [:INT, 25], [:OPERATOR, ">="], [:INT, 27], [:OPERATOR, ">"], [:INT, 28], [:DELIMITER, ";"], [:DELIMITER, "}"]]

    end
    it "quiet/l06.c" do
        expect(tokenize("quiet/lexer/l06.c")).to eq [[:KEYWORD, :int], [:IDENTIFIER, "main"], [:DELIMITER, "("], [:KEYWORD, :void], [:DELIMITER, ")"], [:DELIMITER, "{"], [:DELIMITER, ";"], [:DELIMITER, "}"]]
    end
end

