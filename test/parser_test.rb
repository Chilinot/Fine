require_relative "../lib/parser/parser.rb"

describe "parse" do
    it "parses empty programs" do
        expect(Parser.new.parse("")).to eq Program.new([])
    end
    it "parses int foo;" do
        expect(Parser.new.parse("int foo;")).to eq Program.new([VarDeclaration.new(:INT, "foo")])
    end
    it "parses char bar;" do
        expect(Parser.new.parse("char bar;")).to eq Program.new([VarDeclaration.new(:CHAR, "bar")])
    end
    it "handles void foo;" do
        expect { Parser.new.parse("void bar;") }.to raise_error (Parser::SyntaxError)
    end
    it "parses int foo[42];" do
        expect(Parser.new.parse("int foo[42];")).to eq Program.new([ArrayDeclaration.new(:INT, "foo", 42)])
    end
    it "parses char bar[1337];" do
        expect(Parser.new.parse("char bar[1337];")).to eq Program.new([ArrayDeclaration.new(:CHAR, "bar", 1337)])
    end
    it "handles void foo[2];" do
        expect { Parser.new.parse("void foo[2];") }.to raise_error(Parser::SyntaxError)
    end
    it "parses all variable and array declarations" do
        expect(Parser.new.parse("int foo;\nchar bar;\nint foo[42];char bar[1337];")).to eq Program.new([ VarDeclaration.new(:INT, "foo"),
                                                                                                         VarDeclaration.new(:CHAR, "bar"),
                                                                                                         ArrayDeclaration.new(:INT, "foo", 42),
                                                                                                         ArrayDeclaration.new(:CHAR, "bar", 1337)])
    end
    it "parses extern function declarations without formals" do
        expect(Parser.new.parse("int foo();")).to eq Program.new([ExternFunctionDeclaration.new(:INT, "foo", [])])
        expect(Parser.new.parse("int foo(void);")).to eq Program.new([ExternFunctionDeclaration.new(:INT, "foo", [])])
    end
    it "parses extern function declarations with one formal" do
        expect(Parser.new.parse("int fib(int n);")).to eq Program.new([ExternFunctionDeclaration.new(:INT, "fib", [VarDeclaration.new(:INT, "n")])])
    end
    it "parses extern function declarations with two formal" do
        expect(Parser.new.parse("int max(int a, int b);")).to eq Program.new([ExternFunctionDeclaration.new(:INT, "max", [VarDeclaration.new(:INT, "a"),
                                                                                                                          VarDeclaration.new(:INT, "b")])])
    end


    def make_foo_fn(decl, stmt)
        Program.new([FunctionDeclaration.new(:VOID, "foo", [], FunctionBody.new(decl, stmt))])
    end
    it "parses empty functions" do
        expect(Parser.new.parse("void foo(){}")).to eq make_foo_fn([], [])
    end
    it "parses functions with one variable declaration" do
        expect(Parser.new.parse("void foo(){ int bar; }")).to eq make_foo_fn([VarDeclaration.new(:INT, "bar")], [])
    end
    it "parses functions with multiple variable declaration" do
        expect(Parser.new.parse("void foo(){ int bar; char baz; }")).to eq make_foo_fn([VarDeclaration.new(:INT, "bar"), VarDeclaration.new(:CHAR, "baz")], [])
    end
    it "parses functions with a single integer" do
        expect(Parser.new.parse("void foo(){ 42; }")).to eq make_foo_fn([], [Constant.new(:INT, 42)])
    end
    it "parses functions with a single semicolon" do
        expect(Parser.new.parse("void foo(){ ; }")).to eq make_foo_fn([], [])
    end
    it "parses functions with multiple semicolons" do
        expect(Parser.new.parse("void foo(){ ;;;; ;; ;; ; }")).to eq make_foo_fn([], [])
    end
    it "parses functions with a single char" do
        expect(Parser.new.parse("void foo(){ '\n'; }")).to eq make_foo_fn([], [Constant.new(:CHAR, "\n")])
    end
    it "parses functions with a single identifier" do
        expect(Parser.new.parse("void foo(){ foo; }")).to eq make_foo_fn([], [Identifier.new("foo")])
    end
    it "parses functions with a single array lookup" do
        expect(Parser.new.parse("void foo(){ foo[42]; }")).to eq make_foo_fn([], [ArrayLookup.new("foo", Constant.new(:INT, 42))])
    end
    it "parses functions with a unary minus" do
        expect(Parser.new.parse("void foo(){ -42; }")).to eq make_foo_fn([], [UnaryMinus.new(Constant.new(:INT, 42))])
    end
    it "parses functions with a unary minus" do
        expect(Parser.new.parse("void foo(){ 42--42; }")).to eq make_foo_fn([], [SubNode.new(Constant.new(:INT, 42), UnaryMinus.new(Constant.new(:INT, 42)))])
    end
    it "parses functions with a not expression" do
        expect(Parser.new.parse("void foo(){ !42; }")).to eq make_foo_fn([], [Not.new(Constant.new(:INT, 42))])
    end
    it "parses functions with AddNode" do
        expect(Parser.new.parse("void foo(){ foo + bar; }")).to eq make_foo_fn([], [AddNode.new(Identifier.new("foo"), Identifier.new("bar"))])
    end
    it "parses functions with SubNode" do
        expect(Parser.new.parse("void foo(){ foo - bar; }")).to eq make_foo_fn([], [SubNode.new(Identifier.new("foo"), Identifier.new("bar"))])
    end
    it "parses functions with MulNode" do
        expect(Parser.new.parse("void foo(){ foo * bar; }")).to eq make_foo_fn([], [MulNode.new(Identifier.new("foo"), Identifier.new("bar"))])
    end
    it "parses functions with DivNode" do
        expect(Parser.new.parse("void foo(){ foo / bar; }")).to eq make_foo_fn([], [DivNode.new(Identifier.new("foo"), Identifier.new("bar"))])
    end
    it "parses functions with LessThanNode" do
        expect(Parser.new.parse("void foo(){ foo < bar; }")).to eq make_foo_fn([], [LessThanNode.new(Identifier.new("foo"), Identifier.new("bar"))])
    end
    it "parses functions with GreaterThanNode" do
        expect(Parser.new.parse("void foo(){ foo > bar; }")).to eq make_foo_fn([], [GreaterThanNode.new(Identifier.new("foo"), Identifier.new("bar"))])
    end
    it "parses functions with LessEqualNode" do
        expect(Parser.new.parse("void foo(){ foo <= bar; }")).to eq make_foo_fn([], [LessEqualNode.new(Identifier.new("foo"), Identifier.new("bar"))])
    end
    it "parses functions with GreaterEqualNode" do
        expect(Parser.new.parse("void foo(){ foo >= bar; }")).to eq make_foo_fn([], [GreaterEqualNode.new(Identifier.new("foo"), Identifier.new("bar"))])
    end
    it "parses functions with NotEqualNode" do
        expect(Parser.new.parse("void foo(){ foo != bar; }")).to eq make_foo_fn([], [NotEqualNode.new(Identifier.new("foo"), Identifier.new("bar"))])
    end
    it "parses functions with EqualNode" do
        expect(Parser.new.parse("void foo(){ foo == bar; }")).to eq make_foo_fn([], [EqualNode.new(Identifier.new("foo"), Identifier.new("bar"))])
    end
    it "parses functions with AndNode" do
        expect(Parser.new.parse("void foo(){ foo && bar; }")).to eq make_foo_fn([], [AndNode.new(Identifier.new("foo"), Identifier.new("bar"))])
    end
    it "parses functions with AssignNode" do
        expect(Parser.new.parse("void foo(){ foo = bar; }")).to eq make_foo_fn([], [AssignNode.new(Identifier.new("foo"), Identifier.new("bar"))])
    end
    it "parses functions with multiple AndNodes" do
        expect(Parser.new.parse("void foo(){ foo && bar && 42; }")).to eq make_foo_fn([], [AndNode.new(AndNode.new(Identifier.new("foo"), Identifier.new("bar")), Constant.new(:INT, 42))])
    end
    it "parses functions with parenthesized expressions" do
        expect(Parser.new.parse("void foo(){ (foo + bar); }")).to eq make_foo_fn([], [AddNode.new(Identifier.new("foo"), Identifier.new("bar"))])
    end
    it "parses functions with function call without arguments" do
        expect(Parser.new.parse("void foo(){ foo(); }")).to eq make_foo_fn([], [FunctionCall.new("foo",[])])
    end
    it "parses functions with function call single argument" do
        expect(Parser.new.parse("void foo(){ foo(42); }")).to eq make_foo_fn([], [FunctionCall.new("foo",[Constant.new(:INT, 42)])])
    end
    it "parses functions with function call multiple arguments" do
        expect(Parser.new.parse("void foo(){ foo(42, bar); }")).to eq make_foo_fn([], [FunctionCall.new("foo",[Constant.new(:INT, 42), Identifier.new("bar")])])
    end
    it "parses functions with empty return statment" do
        expect(Parser.new.parse("void foo(){ return; }")).to eq make_foo_fn([], [Return.new])
    end
    it "parses functions with return statment with expr" do
        expect(Parser.new.parse("void foo(){ return 42; }")).to eq make_foo_fn([], [Return.new(Constant.new(:INT, 42))])
    end
    it "parses functions with while statment" do
        expect(Parser.new.parse("void foo(){ while (foo) { bar; } }")).to eq make_foo_fn([], [While.new(Identifier.new("foo"), [Identifier.new("bar")])])
    end
    it "parses functions with simple if statment" do
        expect(Parser.new.parse("void foo(){ if (foo) { bar; } }")).to eq make_foo_fn([], [If.new(Identifier.new("foo"), [Identifier.new("bar")])])
    end
    it "parses functions with if else statment" do
        expect(Parser.new.parse("void foo(){ if (foo) { bar; } else { return; } }")).to eq make_foo_fn([], [If.new(Identifier.new("foo"), [Identifier.new("bar")], [Return.new])])
    end
    it "parses functions with if else if" do
        expect(Parser.new.parse("void foo(){ if (foo) { bar; } else if (bar) { return; } }")).to eq make_foo_fn([],
        [If.new(Identifier.new("foo"),[Identifier.new("bar")], [If.new(Identifier.new("bar"), [Return.new])])])
    end
    it "parses functions with if else if else" do
        expect(Parser.new.parse("void foo(){ if (foo) { bar; } else if (bar) { return; } else { ; } }")).to eq make_foo_fn([],
        [If.new(Identifier.new("foo"),[Identifier.new("bar")], [If.new(Identifier.new("bar"), [Return.new], [])])])
    end
    it "parses functions with if else if else" do
        expect(Parser.new.parse("void foo(){ if (foo) { bar; } else if (bar) { return; } else if (bar) { return; } else if (bar) { return; } else { ; } }")).to eq make_foo_fn([],
        [If.new(Identifier.new("foo"),[Identifier.new("bar")], [If.new(Identifier.new("bar"), [Return.new], [If.new(Identifier.new("bar"), [Return.new], [If.new(Identifier.new("bar"), [Return.new], [])])])])])
    end
end




