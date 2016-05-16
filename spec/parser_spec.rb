require_relative "../lib/parser/parser.rb"

describe "parse" do
    it "parses empty programs" do
        expect(Parser.new.parse("")).to eq ProgramNode.new([])
    end
    it "parses int foo;" do
        expect(Parser.new.parse("int foo;")).to eq ProgramNode.new([VariableDeclarationNode.new(:INT, "foo")])
    end
    it "parses char bar;" do
        expect(Parser.new.parse("char bar;")).to eq ProgramNode.new([VariableDeclarationNode.new(:CHAR, "bar")])
    end
    it "handles void foo;" do
        expect { Parser.new.parse("void bar;") }.to raise_error (Parser::SyntaxError)
    end
    it "parses int foo[42];" do
        expect(Parser.new.parse("int foo[42];")).to eq ProgramNode.new([ArrayDeclarationNode.new(:INT, "foo", 42)])
    end
    it "parses char bar[1337];" do
        expect(Parser.new.parse("char bar[1337];")).to eq ProgramNode.new([ArrayDeclarationNode.new(:CHAR, "bar", 1337)])
    end
    it "handles void foo[2];" do
        expect { Parser.new.parse("void foo[2];") }.to raise_error(Parser::SyntaxError)
    end
    it "parses all variable and array declarations" do
        expect(Parser.new.parse("int foo;\nchar bar;\nint foo[42];char bar[1337];")).to eq ProgramNode.new([ VariableDeclarationNode.new(:INT, "foo"),
                                                                                                         VariableDeclarationNode.new(:CHAR, "bar"),
                                                                                                         ArrayDeclarationNode.new(:INT, "foo", 42),
                                                                                                         ArrayDeclarationNode.new(:CHAR, "bar", 1337)])
    end
    it "parses extern function declarations without formals" do
        expect(Parser.new.parse("int foo(void);")).to eq ProgramNode.new([ExternFunctionDeclarationNode.new(:INT, "foo", [])])
        expect(Parser.new.parse("int foo(void);")).to eq ProgramNode.new([ExternFunctionDeclarationNode.new(:INT, "foo", [])])
    end
    it "parses extern function declarations with one formal" do
        expect(Parser.new.parse("int fib(int n);")).to eq ProgramNode.new([ExternFunctionDeclarationNode.new(:INT, "fib", [VariableDeclarationNode.new(:INT, "n")])])
    end
    it "parses extern function declarations with two formal" do
        expect(Parser.new.parse("int max(int a, int b);")).to eq ProgramNode.new([ExternFunctionDeclarationNode.new(:INT, "max", [VariableDeclarationNode.new(:INT, "a"),
                                                                                                                          VariableDeclarationNode.new(:INT, "b")])])
    end


    def make_foo_fn(decl, stmt)
        ProgramNode.new([FunctionDeclarationNode.new(:VOID, "foo", [], FunctionBodyNode.new(decl, stmt))])
    end
    it "parses empty functions" do
        expect(Parser.new.parse("void foo(void) {}")).to eq make_foo_fn([], [])
    end
    it "parses functions with one variable declaration" do
        expect(Parser.new.parse("void foo(void) { int bar; }")).to eq make_foo_fn([VariableDeclarationNode.new(:INT, "bar")], [])
    end
    it "parses functions with multiple variable declaration" do
        expect(Parser.new.parse("void foo(void) { int bar; char baz; }")).to eq make_foo_fn([VariableDeclarationNode.new(:INT, "bar"), VariableDeclarationNode.new(:CHAR, "baz")], [])
    end
    it "parses functions with a single integer" do
        expect(Parser.new.parse("void foo(void) { 42; }")).to eq make_foo_fn([], [ConstantNode.new(:INT, 42)])
    end
    it "parses functions with a single semicolon" do
        expect(Parser.new.parse("void foo(void) { ; }")).to eq make_foo_fn([], [])
    end
    it "parses functions with multiple semicolons" do
        expect(Parser.new.parse("void foo(void) { ;;;; ;; ;; ; }")).to eq make_foo_fn([], [])
    end
    it "parses functions with a single char" do
        expect(Parser.new.parse("void foo(void) { '\n'; }")).to eq make_foo_fn([], [ConstantNode.new(:CHAR, "\n")])
    end
    it "parses functions with a single identifier" do
        expect(Parser.new.parse("void foo(void) { foo; }")).to eq make_foo_fn([], [IdentifierNode.new("foo")])
    end
    it "parses functions with a single array lookup" do
        expect(Parser.new.parse("void foo(void) { foo[42]; }")).to eq make_foo_fn([], [ArrayLookup.new("foo", ConstantNode.new(:INT, 42))])
    end
    it "parses functions with a unary minus" do
        expect(Parser.new.parse("void foo(void) { -42; }")).to eq make_foo_fn([], [UnaryMinus.new(ConstantNode.new(:INT, 42))])
    end
    it "parses functions with a unary minus" do
        expect(Parser.new.parse("void foo(void) { 42--42; }")).to eq make_foo_fn([], [SubNode.new(ConstantNode.new(:INT, 42), UnaryMinus.new(ConstantNode.new(:INT, 42)))])
    end
    it "parses functions with a not expression" do
        expect(Parser.new.parse("void foo(void) { !42; }")).to eq make_foo_fn([], [Not.new(ConstantNode.new(:INT, 42))])
    end
    it "parses functions with AddNode" do
        expect(Parser.new.parse("void foo(void) { foo + bar; }")).to eq make_foo_fn([], [AddNode.new(IdentifierNode.new("foo"), IdentifierNode.new("bar"))])
    end
    it "parses functions with SubNode" do
        expect(Parser.new.parse("void foo(void) { foo - bar; }")).to eq make_foo_fn([], [SubNode.new(IdentifierNode.new("foo"), IdentifierNode.new("bar"))])
    end
    it "parses functions with MulNode" do
        expect(Parser.new.parse("void foo(void) { foo * bar; }")).to eq make_foo_fn([], [MulNode.new(IdentifierNode.new("foo"), IdentifierNode.new("bar"))])
    end
    it "parses functions with DivNode" do
        expect(Parser.new.parse("void foo(void) { foo / bar; }")).to eq make_foo_fn([], [DivNode.new(IdentifierNode.new("foo"), IdentifierNode.new("bar"))])
    end
    it "parses functions with LessThanNode" do
        expect(Parser.new.parse("void foo(void) { foo < bar; }")).to eq make_foo_fn([], [LessThanNode.new(IdentifierNode.new("foo"), IdentifierNode.new("bar"))])
    end
    it "parses functions with GreaterThanNode" do
        expect(Parser.new.parse("void foo(void) { foo > bar; }")).to eq make_foo_fn([], [GreaterThanNode.new(IdentifierNode.new("foo"), IdentifierNode.new("bar"))])
    end
    it "parses functions with LessEqualNode" do
        expect(Parser.new.parse("void foo(void) { foo <= bar; }")).to eq make_foo_fn([], [LessEqualNode.new(IdentifierNode.new("foo"), IdentifierNode.new("bar"))])
    end
    it "parses functions with GreaterEqualNode" do
        expect(Parser.new.parse("void foo(void) { foo >= bar; }")).to eq make_foo_fn([], [GreaterEqualNode.new(IdentifierNode.new("foo"), IdentifierNode.new("bar"))])
    end
    it "parses functions with NotEqualNode" do
        expect(Parser.new.parse("void foo(void) { foo != bar; }")).to eq make_foo_fn([], [NotEqualNode.new(IdentifierNode.new("foo"), IdentifierNode.new("bar"))])
    end
    it "parses functions with EqualNode" do
        expect(Parser.new.parse("void foo(void) { foo == bar; }")).to eq make_foo_fn([], [EqualNode.new(IdentifierNode.new("foo"), IdentifierNode.new("bar"))])
    end
    it "parses functions with AndNode" do
        expect(Parser.new.parse("void foo(void) { foo && bar; }")).to eq make_foo_fn([], [AndNode.new(IdentifierNode.new("foo"), IdentifierNode.new("bar"))])
    end
    it "parses functions with AssignNode" do
        expect(Parser.new.parse("void foo(void) { foo = bar; }")).to eq make_foo_fn([], [AssignNode.new(IdentifierNode.new("foo"), IdentifierNode.new("bar"))])
    end
    it "parses functions with multiple AndNodes" do
        expect(Parser.new.parse("void foo(void) { foo && bar && 42; }")).to eq make_foo_fn([], [AndNode.new(AndNode.new(IdentifierNode.new("foo"), IdentifierNode.new("bar")), ConstantNode.new(:INT, 42))])
    end
    it "parses functions with parenthesized expressions" do
        expect(Parser.new.parse("void foo(void) { (foo + bar); }")).to eq make_foo_fn([], [AddNode.new(IdentifierNode.new("foo"), IdentifierNode.new("bar"))])
    end
    it "parses functions with function call without arguments" do
        expect(Parser.new.parse("void foo(void) { foo(); }")).to eq make_foo_fn([], [CallNode.new("foo",[])])
    end
    it "parses functions with function call single argument" do
        expect(Parser.new.parse("void foo(void) { foo(42); }")).to eq make_foo_fn([], [CallNode.new("foo",[ConstantNode.new(:INT, 42)])])
    end
    it "parses functions with function call multiple arguments" do
        expect(Parser.new.parse("void foo(void) { foo(42, bar); }")).to eq make_foo_fn([], [CallNode.new("foo",[ConstantNode.new(:INT, 42), IdentifierNode.new("bar")])])
    end
    it "parses functions with empty return statment" do
        expect(Parser.new.parse("void foo(void) { return; }")).to eq make_foo_fn([], [ReturnNode.new(:VOID)])
    end
    it "parses functions with return statment with expr" do
        expect(Parser.new.parse("void foo(void) { return 42; }")).to eq make_foo_fn([], [ReturnNode.new(ConstantNode.new(:INT, 42))])
    end
    it "parses functions with while statment" do
        expect(Parser.new.parse("void foo(void) { while (foo) { bar; } }")).to eq make_foo_fn([], [WhileNode.new(IdentifierNode.new("foo"), [IdentifierNode.new("bar")])])
    end
    it "parses functions with simple if statment" do
        expect(Parser.new.parse("void foo(void) { if (foo) { bar; } }")).to eq make_foo_fn([], [IfNode.new(IdentifierNode.new("foo"), [IdentifierNode.new("bar")])])
    end
    it "parses functions with if else statment" do
        expect(Parser.new.parse("void foo(void) { if (foo) { bar; } else { return; } }")).to eq make_foo_fn([], [IfNode.new(IdentifierNode.new("foo"), [IdentifierNode.new("bar")], [ReturnNode.new(:VOID)])])
    end
    it "parses functions with if else if" do
        expect(Parser.new.parse("void foo(void) { if (foo) { bar; } else if (bar) { return; } }")).to eq make_foo_fn([],
        [IfNode.new(IdentifierNode.new("foo"),[IdentifierNode.new("bar")], [IfNode.new(IdentifierNode.new("bar"), [ReturnNode.new(:VOID)])])])
    end
    it "parses functions with if else if else" do
        expect(Parser.new.parse("void foo(void) { if (foo) { bar; } else if (bar) { return; } else { ; } }")).to eq make_foo_fn([],
        [IfNode.new(IdentifierNode.new("foo"),[IdentifierNode.new("bar")], [IfNode.new(IdentifierNode.new("bar"), [ReturnNode.new(:VOID)], [])])])
    end
    it "parses functions with if else if else" do
        expect(Parser.new.parse("void foo(void) { if (foo) { bar; } else if (bar) { return; } else if (bar) { return; } else if (bar) { return; } else { ; } }")).to eq make_foo_fn([],
        [IfNode.new(IdentifierNode.new("foo"),[IdentifierNode.new("bar")], [IfNode.new(IdentifierNode.new("bar"), [ReturnNode.new(:VOID)], [IfNode.new(IdentifierNode.new("bar"), [ReturnNode.new(:VOID)], [IfNode.new(IdentifierNode.new("bar"), [ReturnNode.new(:VOID)], [])])])])])
    end
end




