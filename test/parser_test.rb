require_relative "../lib/parser/parser.rb"

describe "parse" do
    it "test" do
        expect(Parser.new.parse("int foo;", true)).to eq "int"
    end
end
