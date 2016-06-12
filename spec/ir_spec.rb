require_relative "../lib/parser/parser.rb"
require_relative "../lib/semantic/semantic_analysis.rb"
require_relative "../lib/ir/ir.rb"

describe "ir" do
    def string_to_ast string, show_ast = false
        begin
            ast = Parser.new.parse string
            if semantic_analysis(ast)
                if show_ast
                    puts "---------------------------------"
                    puts ast
                end
                return ast
            end
        rescue Lexer::LexicalError => e
            puts e
        rescue Parser::SyntaxError => e
            puts e
        rescue SemanticError => e
            puts e
        end
    end

    it "handles empty programs" do
        expect(generate_ir (string_to_ast "")).to eq Ir.new []
    end
    it "handle global int variables" do
        expect(generate_ir (string_to_ast "int foo;")).to eq Ir.new [GlobalInt.new("foo")]
    end
    it "handle global char variables" do
        expect(generate_ir (string_to_ast "char foo;")).to eq Ir.new [GlobalChar.new("foo")]
    end
    it "handle global int arrays" do
        expect(generate_ir (string_to_ast "int foo[42];")).to eq Ir.new [GlobalIntArray.new("foo",42)]
    end
    it "handle global char arrays" do
        expect(generate_ir (string_to_ast "char foo[42];")).to eq Ir.new [GlobalCharArray.new("foo",42)]
    end
    it "handle global int and char array" do
        expect(generate_ir (string_to_ast "int foo; char bar[2];")).to eq Ir.new [GlobalInt.new("foo"),GlobalCharArray.new("bar",2)]
    end
    it "ignores extern declaration" do
        expect(generate_ir (string_to_ast "void main(void);")).to eq Ir.new []
    end
    it "handles simple function declaration" do
        expect(generate_ir (string_to_ast "void main(void) {}")).to eq Ir.new [ Function.new("main",:VOID, [],[],[]) ]
    end
    it "handles functions with formals" do
        expect(generate_ir (string_to_ast "void f(int a, int b) {  }")).to eq Ir.new [ Function.new("f",:VOID, [
                                                                                                                FormalArgument.new("a", :INT, Temporary.new(1)),
                                                                                                                FormalArgument.new("b", :INT,  Temporary.new(2))
                                                                                                               ],[],[]) ]
    end
    it "handles functions with explicit empty return" do
        expect(generate_ir (string_to_ast "void main(void) { return; }")).to eq Ir.new [ Function.new("main",:VOID, [],[],[Return.new(:void, :VOID)]) ]
    end
    it "handles functions with local char" do
        expect(generate_ir (string_to_ast "void main(void) { int foo; }")).to eq Ir.new [ Function.new("main",:VOID, [],[LocalInt.new("foo")],[]) ]
    end
    it "handles functions with local int" do
        expect(generate_ir (string_to_ast "void main(void) { char foo; }")).to eq Ir.new [ Function.new("main",:VOID, [],[LocalChar.new("foo")],[]) ]
    end
    it "handles functions with multiple local variables" do
        expect(generate_ir (string_to_ast "void main(void) { int foo; char bar; }")).to eq Ir.new [ Function.new("main",:VOID, [],[LocalInt.new("foo"), LocalChar.new("bar")],[]) ]
    end
    it "handles functions with local int-array" do
        expect(generate_ir (string_to_ast "void main(void) { int foo[42]; }")).to eq Ir.new [ Function.new("main",:VOID, [],[LocalIntArray.new("foo", 42)],[]) ]
    end
    it "handles functions with local char-array" do
        expect(generate_ir (string_to_ast "void main(void) { char foo[22]; }")).to eq Ir.new [ Function.new("main",:VOID, [],[LocalCharArray.new("foo",22)],[]) ]
    end
    it "handles functions returning a int constant" do
        expect(generate_ir (string_to_ast "int main(void) { return 42; }")).to eq Ir.new [ Function.new("main",:INT, [],[],[Return.new(:i32, Constant.new(42))]) ]
    end
    it "handles functions returning a char constant" do
        expect(generate_ir (string_to_ast "char main(void) { return 'a'; }")).to eq Ir.new [ Function.new("main",:CHAR, [],[],[Return.new(:i8, Constant.new(97))]) ]
    end
    it "handles functions returning a 1 + 2" do
        expect(generate_ir (string_to_ast "int main(void) { return 1 + 2; }")).to eq Ir.new [ Function.new("main",:INT, [],[],
            [
                Eval.new(Temporary.new(1), Add.new(Constant.new(1), Constant.new(2))),
                Return.new(:i32, Temporary.new(1))
            ]
        )]
    end
    it "handles functions returning a 1 + 2 - 3" do
        expect(generate_ir (string_to_ast "int main(void) { return 1 + 2 - 3; }")).to eq Ir.new [ Function.new("main",:INT, [],[],
            [
                Eval.new(Temporary.new(1), Add.new(Constant.new(1), Constant.new(2))),
                Eval.new(Temporary.new(2), Sub.new(Temporary.new(1), Constant.new(3))),
                Return.new(:i32, Temporary.new(2))
            ]
        )]
    end
    it "handles many things" do
        ast_nodes = {
                AddNode          => Add,
                SubNode          => Sub,
                MulNode          => Mul,
                DivNode          => Div,
                LessThenNode     => LessThen,
                GreaterThenNode  => GreaterThen,
                LessEqualNode    => LessEqual,
                GreaterEqualNode => GreaterEqual,
                NotEqualNode     => NotEqual,
                EqualNode        => Equal,
                AndNode          => And,
                OrNode           => Or
        }
        ast_nodes.each do |ast, ir|
            expect(generate_ir (string_to_ast "int main(void) { return 1 #{ast.new} 2; }")).to eq Ir.new [ Function.new("main",:INT, [],[],
                [
                    Eval.new(Temporary.new(1), ir.new(Constant.new(1), Constant.new(2))),
                    Return.new(:i32, Temporary.new(1))
                ]
            )]
        end
    end
    it "handles more complex expressions" do
            expect(generate_ir (string_to_ast "int main(void) { return 42 + 2 != 42 - 2 * 33; }")).to eq Ir.new [ Function.new("main",:INT, [],[],
                [
                    Eval.new(Temporary.new(1), Add.new(Constant.new(42), Constant.new(2))),
                    Eval.new(Temporary.new(2), Mul.new(Constant.new(2), Constant.new(33))),
                    Eval.new(Temporary.new(3), Sub.new(Constant.new(42), Temporary.new(2))),
                    Eval.new(Temporary.new(4), NotEqual.new(Temporary.new(1), Temporary.new(3))),
                    Return.new(:i32, Temporary.new(4))
                ]
            )]
    end
    it "handles functions returning a global + local identifiers" do
        expect(generate_ir (string_to_ast "int foo; int main(void) { int bar; return foo + bar; }")).to eq Ir.new [
            GlobalInt.new("foo"),
            Function.new("main",:INT, [],
            [
                LocalInt.new("bar")
            ],
            [
                Eval.new(Temporary.new(1), Add.new(Id.new("foo", true), Id.new("bar", false))),
                Return.new(:i32, Temporary.new(1))
            ])
        ]
    end
    it "handles functions returning array element" do
        expect(generate_ir (string_to_ast "int foo[4]; int main(void) { return foo[2]; }")).to eq Ir.new [
            GlobalIntArray.new("foo", 4),
            Function.new("main",:INT, [], [],
            [
                Return.new(:i32, IntArrayElement.new("foo", 4, Constant.new(2)))
            ])
        ]
    end
    it "handles functions returning array element index by expression" do
        expect(generate_ir (string_to_ast "int foo[4]; int main(void) { return foo[1 / 0 + 10]; }")).to eq Ir.new [
            GlobalIntArray.new("foo", 4),
            Function.new("main",:INT, [], [],
            [
                Eval.new(Temporary.new(1), Div.new(Constant.new(1), Constant.new(0))),
                Eval.new(Temporary.new(2), Add.new(Temporary.new(1), Constant.new(10))),
                Return.new(:i32, IntArrayElement.new("foo", 4, Temporary.new(2)))
            ])
        ]
    end
    it "handles functions returning negated array element" do
        expect(generate_ir (string_to_ast "int foo[4]; int main(void) { return -foo[2]; }")).to eq Ir.new [
            GlobalIntArray.new("foo", 4),
            Function.new("main",:INT, [], [],
            [
                Eval.new(Temporary.new(1), Sub.new(Constant.new(0), IntArrayElement.new("foo", 4, Constant.new(2)))),
                Return.new(:i32, Temporary.new(1))
            ])
        ]
    end
    it "handles functions returning negated array element" do
        expect(generate_ir (string_to_ast "int foo[4]; int main(void) { return !foo[2]; }")).to eq Ir.new [
            GlobalIntArray.new("foo", 4),
            Function.new("main",:INT, [], [],
            [
                Eval.new(Temporary.new(1), Not.new(IntArrayElement.new("foo", 4, Constant.new(2)))),
                Return.new(:i32, Temporary.new(1))
            ])
        ]
    end
    it "handles functions returning casted array element" do
        expect(generate_ir (string_to_ast "char foo[4]; int main(void) { return (int)foo[2]; }")).to eq Ir.new [
            GlobalCharArray.new("foo", 4),
            Function.new("main",:INT, [], [],
            [
                Eval.new(Temporary.new(1), Cast.new(CharArrayElement.new("foo", 4, Constant.new(2)), :CHAR, :INT)),
                Return.new(:i32, Temporary.new(1))
            ])
        ]
    end
    it "handles global variable assignment" do
        expect(generate_ir (string_to_ast "int foo; int main(void) { foo = 42; return 0; }")).to eq Ir.new [
            GlobalInt.new("foo"),
            Function.new("main",:INT, [], [],
            [
                Store.new(:INT, Id.new("foo", true), Constant.new(42)),
                Return.new(:i32, Constant.new(0))
            ])
        ]
    end
    it "handles global array assignment" do
        expect(generate_ir (string_to_ast "int foo[42]; int main(void) { foo[4] = 42; return 0; }")).to eq Ir.new [
            GlobalIntArray.new("foo", 42),
            Function.new("main",:INT, [], [],
            [
                Store.new(:INT, IntArrayElement.new("foo", 42, Constant.new(4)), Constant.new(42)),
                Return.new(:i32, Constant.new(0))
            ])
        ]
    end
    it "can assign expressions to global variables" do
        expect(generate_ir (string_to_ast "int foo; int main(void) { foo = 20 + 10 + 10 + 2; return 0; }")).to eq Ir.new [
            GlobalInt.new("foo"),
            Function.new("main",:INT, [], [],
            [
                Eval.new(Temporary.new(1), Add.new(Constant.new(20), Constant.new(10))),
                Eval.new(Temporary.new(2), Add.new(Temporary.new(1), Constant.new(10))),
                Eval.new(Temporary.new(3), Add.new(Temporary.new(2), Constant.new(2))),
                Store.new(:INT, Id.new("foo", true), Temporary.new(3)),
                Return.new(:i32, Constant.new(0))
            ])
        ]
    end

    it "handles function calls without arguments" do
        expect(generate_ir (string_to_ast "int foo; int main(void) { foo = main(); return 0; }")).to eq Ir.new [
            GlobalInt.new("foo"),
            Function.new("main",:INT, [], [],
            [
                Eval.new(Temporary.new(1), Call.new(Id.new("main", true), [])),
                Store.new(:INT, Id.new("foo", true), Temporary.new(1)),
                Return.new(:i32, Constant.new(0))
            ])
        ]
    end
    it "handles function call with single argument, returning a value" do
        expect(generate_ir (string_to_ast "int id(int value) { return value; } int main(void) { id(42); return 0; }")).to eq Ir.new [
            Function.new("id", :INT, [FormalArgument.new("value", :INT, Temporary.new(1))], [],
            [
                Return.new(:i32, Id.new("value", false))
            ]),
            Function.new("main",:INT, [], [],
            [
                Eval.new(Temporary.new(1), Call.new(Id.new("id", true), [Constant.new(42)])),
                Return.new(:i32, Constant.new(0))
            ])
        ]
    end
    it "handles function call with complex expression, returning a value" do
        expect(generate_ir (string_to_ast "int id(int value) { return value; } int main(void) { id(20 + 10 + 10 + 2); return 0; }")).to eq Ir.new [
            Function.new("id", :INT, [FormalArgument.new("value", :INT, Temporary.new(1))], [],
            [
                Return.new(:i32, Id.new("value", false))
            ]),
            Function.new("main",:INT, [], [],
            [
                Eval.new(Temporary.new(1), Add.new(Constant.new(20), Constant.new(10))),
                Eval.new(Temporary.new(2), Add.new(Temporary.new(1), Constant.new(10))),
                Eval.new(Temporary.new(3), Add.new(Temporary.new(2), Constant.new(2))),
                Eval.new(Temporary.new(4), Call.new(Id.new("id", true), [Temporary.new(3)])),
                Return.new(:i32, Constant.new(0))
            ])
        ]
    end
    it "handles while loops" do
        expect(generate_ir (string_to_ast "int main(void) { int i; while (i) { i = i - 1; } return 0; }")).to eq Ir.new [
            Function.new("main",:INT, [],
            [
                LocalInt.new("i")
            ],[
                Jump.new(Label.new("while_start", 1)),
                Label.new("while_start", 1),
                    Branch.new(Id.new("i", false), Label.new("while_body", 2), Label.new("while_end", 3)),

                Label.new("while_body", 2),
                    Eval.new(Temporary.new(1), Sub.new(Id.new("i", false), Constant.new(1))),
                    Store.new(:INT, Id.new("i", false), Temporary.new(1)),
                    Jump.new(Label.new("while_start", 1)),

                Label.new("while_end", 3),
                Return.new(:i32, Constant.new(0))
            ])
        ]
    end
    it "handles while loops with complex condition" do
        expect(generate_ir (string_to_ast "int main(void) { int i; while (i * 42 + 3) { i = i - 1; } return 0; }")).to eq Ir.new [
            Function.new("main",:INT, [],
            [
                LocalInt.new("i")
            ],[
                Jump.new(Label.new("while_start", 1)),
                Label.new("while_start", 1),
                    Eval.new(Temporary.new(1), Mul.new(Id.new("i", false), Constant.new(42))),
                    Eval.new(Temporary.new(2), Add.new(Temporary.new(1), Constant.new(3))),
                    Branch.new(Temporary.new(2), Label.new("while_body", 2), Label.new("while_end", 3)),

                Label.new("while_body", 2),
                    Eval.new(Temporary.new(3), Sub.new(Id.new("i", false), Constant.new(1))),
                    Store.new(:INT, Id.new("i", false), Temporary.new(3)),
                    Jump.new(Label.new("while_start", 1)),

                Label.new("while_end", 3),
                Return.new(:i32, Constant.new(0))
            ])
        ]
    end
    it "handles if statments" do
        expect(generate_ir (string_to_ast "int main(void) { int i; if (i) { 42; }  return 0; }")).to eq Ir.new [
            Function.new("main",:INT, [],
            [
                LocalInt.new("i")
            ],[
                Branch.new(Id.new("i", false), Label.new("if_then", 1), Label.new("if_end", 2)),
                Label.new("if_then", 1),
                    # Constant.new(42),  # Don't emit ir for stupid code!
                    Jump.new(Label.new("if_end", 2)),
                Label.new("if_end", 2),
                Return.new(:i32, Constant.new(0))
            ])
        ]
    end
    it "handles if else statments" do
        expect(generate_ir (string_to_ast "int main(void) { int i; if (i) { 42; } else { i; }  return 0; }")).to eq Ir.new [
            Function.new("main",:INT, [],
            [
                LocalInt.new("i")
            ],[
                Branch.new(Id.new("i", false), Label.new("if_then", 1), Label.new("if_else", 2)),
                Label.new("if_then", 1),
                    # Constant.new(42),  # Don't emit ir for stupid code!
                    Jump.new(Label.new("if_end", 3)),
                Label.new("if_else", 2),
                    # Id.new("i", false),  # Don't emit ir for stupid code!
                    Jump.new(Label.new("if_end", 3)),
                Label.new("if_end", 3),
                Return.new(:i32, Constant.new(0))
            ])
        ]
    end
    it "handles else if statments" do
        expect(generate_ir (string_to_ast "int main(void) { int i; if (i) { 42; } else if (42) { i; } else { 7; }  return 0; }")).to eq Ir.new [
            Function.new("main",:INT, [],
            [
                LocalInt.new("i")
            ],[
                Branch.new(Id.new("i", false), Label.new("if_then", 1), Label.new("if_else", 2)),
                Label.new("if_then", 1),
                    # Constant.new(42),  # Don't emit ir for stupid code!
                    Jump.new(Label.new("if_end", 3)),
                Label.new("if_else", 2),

                    Branch.new(Constant.new(42), Label.new("if_then", 4), Label.new("if_else", 5)),
                    Label.new("if_then", 4),
                        # Constant.new(42),  # Don't emit ir for stupid code!
                        Jump.new(Label.new("if_end", 6)),
                    Label.new("if_else", 5),
                        # Id.new("i", false),  # Don't emit ir for stupid code!
                        Jump.new(Label.new("if_end", 6)),
                    Label.new("if_end", 6),
                    # Id.new("i", false),  # Don't emit ir for stupid code!
                    Jump.new(Label.new("if_end", 3)),
                Label.new("if_end", 3),
                Return.new(:i32, Constant.new(0))
            ])
        ]
    end
    it "handles if statments with non-trivial condition" do
        expect(generate_ir (string_to_ast "int main(void) { int i; if (i < 10 + 1) { 42; }  return 0; }")).to eq Ir.new [
            Function.new("main",:INT, [],
            [
                LocalInt.new("i")
            ],[
                Eval.new(Temporary.new(1), Add.new(Constant.new(10), Constant.new(1))),
                Eval.new(Temporary.new(2), LessThen.new(Id.new("i", false), Temporary.new(1))),
                Branch.new(Temporary.new(2), Label.new("if_then", 1), Label.new("if_end", 2)),
                Label.new("if_then", 1),
                    # Constant.new(42),  # Don't emit ir for stupid code!
                    Jump.new(Label.new("if_end", 2)),
                Label.new("if_end", 2),
                Return.new(:i32, Constant.new(0))
            ])
        ]
    end
end
