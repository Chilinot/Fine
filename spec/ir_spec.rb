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
        expect(generate_ir (string_to_ast "void main(void) {}")).to eq Ir.new [ Function.new("main",:void, [],[],[]) ]
    end
    it "handles functions with formals" do
        expect(generate_ir (string_to_ast "void f(int a, int b) {  }")).to eq Ir.new [ Function.new("f",:void, [
                                                                                                                FormalArgument.new("a", :i32, Temporary.new(1)),
                                                                                                                FormalArgument.new("b", :i32,  Temporary.new(2))
                                                                                                               ],[],[]) ]
    end
    it "handles functions with explicit empty return" do
        expect(generate_ir (string_to_ast "void main(void) { return; }")).to eq Ir.new [ Function.new("main",:void, [],[],[Return.new(:void, :VOID)]) ]
    end
    it "handles functions with local char" do
        expect(generate_ir (string_to_ast "void main(void) { int foo; }")).to eq Ir.new [ Function.new("main",:void, [],[LocalInt.new("foo")],[]) ]
    end
    it "handles functions with local int" do
        expect(generate_ir (string_to_ast "void main(void) { char foo; }")).to eq Ir.new [ Function.new("main",:void, [],[LocalChar.new("foo")],[]) ]
    end
    it "handles functions with multiple local variables" do
        expect(generate_ir (string_to_ast "void main(void) { int foo; char bar; }")).to eq Ir.new [ Function.new("main",:void, [],[LocalInt.new("foo"), LocalChar.new("bar")],[]) ]
    end
    it "handles functions with local int-array" do
        expect(generate_ir (string_to_ast "void main(void) { int foo[42]; }")).to eq Ir.new [ Function.new("main",:void, [],[LocalIntArray.new("foo", 42)],[]) ]
    end
    it "handles functions with local char-array" do
        expect(generate_ir (string_to_ast "void main(void) { char foo[22]; }")).to eq Ir.new [ Function.new("main",:void, [],[LocalCharArray.new("foo",22)],[]) ]
    end
    it "handles functions returning a int constant" do
        expect(generate_ir (string_to_ast "int main(void) { return 42; }")).to eq Ir.new [ Function.new("main",:i32, [],[],[Return.new(:i32, Constant.new(:i32, 42))]) ]
    end
    it "handles functions returning a char constant" do
        expect(generate_ir (string_to_ast "char main(void) { return 'a'; }")).to eq Ir.new [ Function.new("main",:i8, [],[],[Return.new(:i8, Constant.new(:i8, 97))]) ]
    end
    it "handles functions returning a 1 + 2" do
        expect(generate_ir (string_to_ast "int main(void) { return 1 + 2; }")).to eq Ir.new [ Function.new("main",:i32, [],[],
            [
                Eval.new(Temporary.new(1), Add.new(:i32, Constant.new(:i32, 1), Constant.new(:i32, 2))),
                Return.new(:i32, Temporary.new(1))
            ]
        )]
    end
    it "handles functions returning a 1 + 2 - 3" do
        expect(generate_ir (string_to_ast "int main(void) { return 1 + 2 - 3; }")).to eq Ir.new [ Function.new("main",:i32, [],[],
            [
                Eval.new(Temporary.new(1), Add.new(:i32, Constant.new(:i32, 1), Constant.new(:i32, 2))),
                Eval.new(Temporary.new(2), Sub.new(:i32, Temporary.new(1), Constant.new(:i32, 3))),
                Return.new(:i32, Temporary.new(2))
            ]
        )]
    end
    it "handles aritmeticoperators" do
        ast_nodes = {
                AddNode          => Add,
                SubNode          => Sub,
                MulNode          => Mul,
                DivNode          => Div,
        }
        ast_nodes.each do |ast, ir|
            expect(generate_ir (string_to_ast "int main(void) { return 1 #{ast.new} 2; }")).to eq Ir.new [ Function.new("main",:i32, [],[],
                [
                    Eval.new(Temporary.new(1), ir.new(:i32, Constant.new(:i32, 1), Constant.new(:i32, 2))),
                    Return.new(:i32, Temporary.new(1))
                ]
            )]
        end
    end

    it "handles boolean operators" do
        ast_nodes = {
                LessThenNode     => LessThen,
                GreaterThenNode  => GreaterThen,
                LessEqualNode    => LessEqual,
                GreaterEqualNode => GreaterEqual,
                NotEqualNode     => NotEqual,
                EqualNode        => Equal,
        }
        ast_nodes.each do |ast, ir|
            expect(generate_ir (string_to_ast "int main(void) { return 1 #{ast.new} 2; }")).to eq Ir.new [ Function.new("main",:i32, [],[],
                [
                    Eval.new(Temporary.new(1), ir.new(:i32, Constant.new(:i32, 1), Constant.new(:i32, 2))),
                    Eval.new(Temporary.new(2), ZeroExtend.new(Temporary.new(1), :i1, :i32)),
                    Return.new(:i32, Temporary.new(2))
                ]
            )]
        end
    end

    it "handles && operator" do
            expect(generate_ir (string_to_ast "int main(void) { return 1 && 2; }")).to eq Ir.new [ Function.new("main",:i32, [],[],
                [
                    Eval.new(Temporary.new(1), Compare.new(:i32, Constant.new(:i32, 1))),
                    Eval.new(Temporary.new(2), Compare.new(:i32, Constant.new(:i32, 2))),
                    Eval.new(Temporary.new(3), And.new(:i1, Temporary.new(1), Temporary.new(2))),
                    Eval.new(Temporary.new(4), ZeroExtend.new(Temporary.new(3), :i1, :i32)),
                    Return.new(:i32, Temporary.new(4))
                ]
            )]
    end

    it "handles || operator" do
            expect(generate_ir (string_to_ast "int main(void) { return 1 || 2; }")).to eq Ir.new [ Function.new("main",:i32, [],[],
                [
                    Eval.new(Temporary.new(1), Or.new(:i32, Constant.new(:i32, 1), Constant.new(:i32, 2))),
                    Eval.new(Temporary.new(2), Compare.new(:i32, Temporary.new(1))),
                    Eval.new(Temporary.new(3), ZeroExtend.new(Temporary.new(2), :i1, :i32)),
                    Return.new(:i32, Temporary.new(3))
                ]
            )]
    end

    it "handles more complex expressions" do
            expect(generate_ir (string_to_ast "int main(void) { return 42 + 2 != 42 - 2 * 33; }")).to eq Ir.new [ Function.new("main",:i32, [],[],
                [
                    Eval.new(Temporary.new(1), Add.new(:i32, Constant.new(:i32, 42), Constant.new(:i32, 2))),
                    Eval.new(Temporary.new(2), Mul.new(:i32, Constant.new(:i32, 2), Constant.new(:i32, 33))),
                    Eval.new(Temporary.new(3), Sub.new(:i32, Constant.new(:i32, 42), Temporary.new(2))),
                    Eval.new(Temporary.new(4), NotEqual.new(:i32, Temporary.new(1), Temporary.new(3))),
                    Eval.new(Temporary.new(5), ZeroExtend.new(Temporary.new(4), :i1, :i32)),
                    Return.new(:i32, Temporary.new(5))
                ]
            )]
    end
    it "handles functions returning a global + local identifiers" do
        expect(generate_ir (string_to_ast "int foo; int main(void) { int bar; return foo + bar; }")).to eq Ir.new [
            GlobalInt.new("foo"),
            Function.new("main",:i32, [],
            [
                LocalInt.new("bar")
            ],
            [
                Eval.new(Temporary.new(1), Load.new(:i32, Id.new("foo", true))),
                Eval.new(Temporary.new(2), Load.new(:i32, Id.new("bar", false))),
                Eval.new(Temporary.new(3), Add.new(:i32, Temporary.new(1), Temporary.new(2))),
                Return.new(:i32, Temporary.new(3))
            ])
        ]
    end
    it "handles functions returning array element" do
        expect(generate_ir (string_to_ast "int foo[4]; int main(void) { return foo[2]; }")).to eq Ir.new [
            GlobalIntArray.new("foo", 4),
            Function.new("main",:i32, [], [],
            [
                Eval.new(Temporary.new(1), ArrayElement.new(:i32, "foo", 4, Constant.new(:i32, 2))),
                Eval.new(Temporary.new(2), Load.new(:i32, Temporary.new(1))),
                Return.new(:i32, Temporary.new(2))
            ])
        ]
    end
    it "handles functions returning array element index by expression" do
        expect(generate_ir (string_to_ast "int foo[4]; int main(void) { return foo[1 / 0 + 10]; }")).to eq Ir.new [
            GlobalIntArray.new("foo", 4),
            Function.new("main",:i32, [], [],
            [
                Eval.new(Temporary.new(1), Div.new(:i32, Constant.new(:i32, 1), Constant.new(:i32, 0))),
                Eval.new(Temporary.new(2), Add.new(:i32, Temporary.new(1), Constant.new(:i32, 10))),
                Eval.new(Temporary.new(3), ArrayElement.new(:i32, "foo", 4, Temporary.new(2))),
                Eval.new(Temporary.new(4), Load.new(:i32, Temporary.new(3))),
                Return.new(:i32, Temporary.new(4))
            ])
        ]
    end
    it "handles functions returning negated array element" do
        expect(generate_ir (string_to_ast "int foo[4]; int main(void) { return -foo[2]; }")).to eq Ir.new [
            GlobalIntArray.new("foo", 4),
            Function.new("main",:i32, [], [],
            [
                Eval.new(Temporary.new(1), ArrayElement.new(:i32, "foo", 4, Constant.new(:i32, 2))),
                Eval.new(Temporary.new(2), Load.new(:i32, Temporary.new(1))),
                Eval.new(Temporary.new(3), Sub.new(:i32, Constant.new(:i32, 0), Temporary.new(2))),
                Return.new(:i32, Temporary.new(3))
            ])
        ]
    end
    it "handles functions returning ! array element" do
        expect(generate_ir (string_to_ast "int foo[4]; int main(void) { return !foo[2]; }")).to eq Ir.new [
            GlobalIntArray.new("foo", 4),
            Function.new("main",:i32, [], [],
            [
                Eval.new(Temporary.new(1), ArrayElement.new(:i32, "foo", 4, Constant.new(:i32, 2))),
                Eval.new(Temporary.new(2), Load.new(:i32, Temporary.new(1))),
                Eval.new(Temporary.new(3), Not.new(Temporary.new(2))),
                Return.new(:i32, Temporary.new(3))
            ])
        ]
    end
    it "handles functions returning casted array element" do
        expect(generate_ir (string_to_ast "char foo[4]; int main(void) { return (int)foo[2]; }")).to eq Ir.new [
            GlobalCharArray.new("foo", 4),
            Function.new("main",:i32, [], [],
            [
                Eval.new(Temporary.new(1), ArrayElement.new(:i8, "foo", 4, Constant.new(:i32, 2))),
                Eval.new(Temporary.new(2), Load.new(:i8, Temporary.new(1))),
                Eval.new(Temporary.new(3), Cast.new(Temporary.new(2), :i8, :i32)),
                Return.new(:i32, Temporary.new(3))
            ])
        ]
    end
    it "handles global variable assignment" do
        expect(generate_ir (string_to_ast "int foo; int main(void) { foo = 42; return 0; }")).to eq Ir.new [
            GlobalInt.new("foo"),
            Function.new("main",:i32, [], [],
            [
                Store.new(:i32, Id.new("foo", true), Constant.new(:i32, 42)),
                Return.new(:i32, Constant.new(:i32, 0))
            ])
        ]
    end
    it "handles global array assignment" do
        expect(generate_ir (string_to_ast "int foo[42]; int main(void) { foo[4] = 42; return 0; }")).to eq Ir.new [
            GlobalIntArray.new("foo", 42),
            Function.new("main",:i32, [], [],
            [
                Eval.new(Temporary.new(1), ArrayElement.new(:i32, "foo", 42, Constant.new(:i32, 4))),
                Store.new(:i32, Temporary.new(1), Constant.new(:i32, 42)),
                Return.new(:i32, Constant.new(:i32, 0))
            ])
        ]
    end
    it "can assign expressions to global variables" do
        expect(generate_ir (string_to_ast "int foo; int main(void) { foo = 20 + 10 + 10 + 2; return 0; }")).to eq Ir.new [
            GlobalInt.new("foo"),
            Function.new("main",:i32, [], [],
            [
                Eval.new(Temporary.new(1), Add.new(:i32, Constant.new(:i32, 20), Constant.new(:i32, 10))),
                Eval.new(Temporary.new(2), Add.new(:i32, Temporary.new(1), Constant.new(:i32, 10))),
                Eval.new(Temporary.new(3), Add.new(:i32, Temporary.new(2), Constant.new(:i32, 2))),
                Store.new(:i32, Id.new("foo", true), Temporary.new(3)),
                Return.new(:i32, Constant.new(:i32, 0))
            ])
        ]
    end

    it "handles function calls without arguments" do
        expect(generate_ir (string_to_ast "int foo; int main(void) { foo = main(); return 0; }")).to eq Ir.new [
            GlobalInt.new("foo"),
            Function.new("main",:i32, [], [],
            [
                Eval.new(Temporary.new(1), Call.new(:i32, Id.new("main", true), [])),
                Store.new(:i32, Id.new("foo", true), Temporary.new(1)),
                Return.new(:i32, Constant.new(:i32, 0))
            ])
        ]
    end
    it "handles function call with single argument, returning a value" do
        expect(generate_ir (string_to_ast "int id(int value) { return value; } int main(void) { id(42); return 0; }")).to eq Ir.new [
            Function.new("id", :i32, [FormalArgument.new("value", :i32, Temporary.new(1))], [],
            [
                Eval.new(Temporary.new(2), Load.new(:i32, Id.new("value", false))),
                Return.new(:i32, Temporary.new(2))
            ]),
            Function.new("main",:i32, [], [],
            [
                Eval.new(Temporary.new(1), Call.new(:i32, Id.new("id", true), [{:type => :i32, :id => Constant.new(:i32, 42)}])),
                Return.new(:i32, Constant.new(:i32, 0))
            ])
        ]
    end
    it "handles function call with complex expression, returning a value" do
        expect(generate_ir (string_to_ast "int id(int value) { return value; } int main(void) { id(20 + 10 + 10 + 2); return 0; }")).to eq Ir.new [
            Function.new("id", :i32, [FormalArgument.new("value", :i32, Temporary.new(1))], [],
            [
                Eval.new(Temporary.new(2), Load.new(:i32, Id.new("value", false))),
                Return.new(:i32, Temporary.new(2))
            ]),
            Function.new("main",:i32, [], [],
            [
                Eval.new(Temporary.new(1), Add.new(:i32, Constant.new(:i32, 20), Constant.new(:i32, 10))),
                Eval.new(Temporary.new(2), Add.new(:i32, Temporary.new(1), Constant.new(:i32, 10))),
                Eval.new(Temporary.new(3), Add.new(:i32, Temporary.new(2), Constant.new(:i32, 2))),
                Eval.new(Temporary.new(4), Call.new(:i32, Id.new("id", true), [{:type => :i32, :id => Temporary.new(3)}])),
                Return.new(:i32, Constant.new(:i32, 0))
            ])
        ]
    end
    it "handles while loops" do
        expect(generate_ir (string_to_ast "int main(void) { int i; while (i) { i = i - 1; } return 0; }")).to eq Ir.new [
            Function.new("main",:i32, [],
            [
                LocalInt.new("i")
            ],[
                Jump.new(Label.new("while_start", 1)),
                Label.new("while_start", 1),
                    Eval.new(Temporary.new(1), Load.new(:i32, Id.new("i", false))),
                    Eval.new(Temporary.new(2), Compare.new(:i32, Temporary.new(1))),
                    Branch.new(Temporary.new(2), Label.new("while_body", 2), Label.new("while_end", 3)),

                Label.new("while_body", 2),
                    Eval.new(Temporary.new(3), Load.new(:i32, Id.new("i", false))),
                    Eval.new(Temporary.new(4), Sub.new(:i32, Temporary.new(3), Constant.new(:i32, 1))),
                    Store.new(:i32, Id.new("i", false), Temporary.new(4)),
                    Jump.new(Label.new("while_start", 1)),

                Label.new("while_end", 3),
                Return.new(:i32, Constant.new(:i32, 0))
            ])
        ]
    end
    it "handles while loops with complex condition" do
        expect(generate_ir (string_to_ast "int main(void) { int i; while (i * 42 + 3) { i = i - 1; } return 0; }")).to eq Ir.new [
            Function.new("main",:i32, [],
            [
                LocalInt.new("i")
            ],[
                Jump.new(Label.new("while_start", 1)),
                Label.new("while_start", 1),
                    Eval.new(Temporary.new(1), Load.new(:i32, Id.new("i", false))),
                    Eval.new(Temporary.new(2), Mul.new(:i32, Temporary.new(1), Constant.new(:i32, 42))),
                    Eval.new(Temporary.new(3), Add.new(:i32, Temporary.new(2), Constant.new(:i32, 3))),
                    Eval.new(Temporary.new(4), Compare.new(:i32, Temporary.new(3))),
                    Branch.new(Temporary.new(4), Label.new("while_body", 2), Label.new("while_end", 3)),

                Label.new("while_body", 2),
                    Eval.new(Temporary.new(5), Load.new(:i32, Id.new("i", false))),
                    Eval.new(Temporary.new(6), Sub.new(:i32, Temporary.new(5), Constant.new(:i32, 1))),
                    Store.new(:i32, Id.new("i", false), Temporary.new(6)),
                    Jump.new(Label.new("while_start", 1)),

                Label.new("while_end", 3),
                Return.new(:i32, Constant.new(:i32, 0))
            ])
        ]
    end
    it "handles if statments" do
        expect(generate_ir (string_to_ast "int main(void) { int i; if (i) { 42; }  return 0; }")).to eq Ir.new [
            Function.new("main",:i32, [],
            [
                LocalInt.new("i")
            ],[
                Eval.new(Temporary.new(1), Load.new(:i32, Id.new("i", false))),
                Eval.new(Temporary.new(2), Compare.new(:i32, Temporary.new(1))),
                Branch.new(Temporary.new(2), Label.new("if_then", 1), Label.new("if_end", 2)),
                Label.new("if_then", 1),
                    # Constant.new(:i32, 42),  # Don't emit ir for stupid code!
                    Jump.new(Label.new("if_end", 2)),
                Label.new("if_end", 2),
                Return.new(:i32, Constant.new(:i32, 0))
            ])
        ]
    end
    it "handles if else statments" do
        expect(generate_ir (string_to_ast "int main(void) { int i; if (i) { 42; } else { i; }  return 0; }")).to eq Ir.new [
            Function.new("main",:i32, [],
            [
                LocalInt.new("i")
            ],[
                Eval.new(Temporary.new(1), Load.new(:i32, Id.new("i", false))),
                Eval.new(Temporary.new(2), Compare.new(:i32, Temporary.new(1))),
                Branch.new(Temporary.new(2), Label.new("if_then", 1), Label.new("if_else", 2)),
                Label.new("if_then", 1),
                    # Constant.new(:i32, 42),  # Don't emit ir for stupid code!
                    Jump.new(Label.new("if_end", 3)),
                Label.new("if_else", 2),
                    Eval.new(Temporary.new(3), Load.new(:i32, Id.new("i", false))),  # Ok, emit stupid code!
                    Jump.new(Label.new("if_end", 3)),
                Label.new("if_end", 3),
                Return.new(:i32, Constant.new(:i32, 0))
            ])
        ]
    end
    it "handles if else if statments" do
        expect(generate_ir (string_to_ast "int main(void) { int i; if (i) { 42; } else if (42) { 32; } else { 7; }  return 0; }")).to eq Ir.new [
            Function.new("main",:i32, [],
            [
                LocalInt.new("i")
            ],[
                Eval.new(Temporary.new(1), Load.new(:i32, Id.new("i", false))),
                Eval.new(Temporary.new(2), Compare.new(:i32, Temporary.new(1))),
                Branch.new(Temporary.new(2), Label.new("if_then", 1), Label.new("if_else", 2)),
                Label.new("if_then", 1),
                    # Constant.new(:i32, 42),  # Don't emit ir for stupid code!
                    Jump.new(Label.new("if_end", 3)),
                Label.new("if_else", 2),

                    Eval.new(Temporary.new(3), Compare.new(:i32, Constant.new(:i32, 42))),
                    Branch.new(Temporary.new(3), Label.new("if_then", 4), Label.new("if_else", 5)),
                    Label.new("if_then", 4),
                        # Constant.new(:i32, 42),  # Don't emit ir for stupid code!
                        Jump.new(Label.new("if_end", 6)),
                    Label.new("if_else", 5),
                        # Id.new("i", false),  # Don't emit ir for stupid code!
                        Jump.new(Label.new("if_end", 6)),
                    Label.new("if_end", 6),
                    # Id.new("i", false),  # Don't emit ir for stupid code!
                    Jump.new(Label.new("if_end", 3)),
                Label.new("if_end", 3),
                Return.new(:i32, Constant.new(:i32, 0))
            ])
        ]
    end
    it "handles if statments with non-trivial condition" do
        expect(generate_ir (string_to_ast "int main(void) { int i; if (i < 10 + 1) { 42; }  return 0; }")).to eq Ir.new [
            Function.new("main",:i32, [],
            [
                LocalInt.new("i")
            ],[
                Eval.new(Temporary.new(1), Load.new(:i32, Id.new("i", false))),
                Eval.new(Temporary.new(2), Add.new(:i32, Constant.new(:i32, 10), Constant.new(:i32, 1))),
                Eval.new(Temporary.new(3), LessThen.new(:i32, Temporary.new(1), Temporary.new(2))),
                Eval.new(Temporary.new(4), ZeroExtend.new(Temporary.new(3), :i1, :i32)),
                Eval.new(Temporary.new(5), Compare.new(:i32, Temporary.new(4))),
                Branch.new(Temporary.new(5), Label.new("if_then", 1), Label.new("if_end", 2)),
                Label.new("if_then", 1),
                    # Constant.new(:i32, 42),  # Don't emit ir for stupid code!
                    Jump.new(Label.new("if_end", 2)),
                Label.new("if_end", 2),
                Return.new(:i32, Constant.new(:i32, 0))
            ])
        ]
    end
end
