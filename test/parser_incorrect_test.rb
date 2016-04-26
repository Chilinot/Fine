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
    it "parser/pe02.c" do
        expect { parse("parser/pe02.c").inspect }.to raise_error Parser::SyntaxError
    end
    it "parser/pe03.c" do
        expect { parse("parser/pe03.c").inspect }.to raise_error Parser::SyntaxError
    end
    it "parser/pe04.c" do
        expect { parse("parser/pe04.c").inspect }.to raise_error Parser::SyntaxError
    end
    it "parser/pe05.c" do
        expect { parse("parser/pe05.c").inspect }.to raise_error Parser::SyntaxError
    end
    it "parser/pe06.c" do
        expect { parse("parser/pe06.c").inspect }.to raise_error Parser::SyntaxError
    end
    it "parser/pe07.c" do
        expect { parse("parser/pe07.c").inspect }.to raise_error Parser::SyntaxError
    end
    it "parser/pe08.c" do
        expect { parse("parser/pe08.c").inspect }.to raise_error Parser::SyntaxError
    end
    it "parser/pe09.c" do
        expect { parse("parser/pe09.c").inspect }.to raise_error Parser::SyntaxError
    end
    it "parser/pe10.c" do
        expect { parse("parser/pe10.c").inspect }.to raise_error Parser::SyntaxError
    end
    it "parser/pe11.c" do
        expect { parse("parser/pe11.c").inspect }.to raise_error Parser::SyntaxError
    end
    it "parser/pe12.c" do
        expect { parse("parser/pe12.c").inspect }.to raise_error Parser::SyntaxError
    end
    it "parser/pe13.c" do
        expect { parse("parser/pe13.c").inspect }.to raise_error Parser::SyntaxError
    end
    it "parser/pe14.c" do
        expect { parse("parser/pe14.c").inspect }.to raise_error Parser::SyntaxError
    end
end
