require_relative "../lib/parser/parser.rb"
require_relative "../lib/semantic/semantic_analysis.rb"
require_relative "../lib/ir/ir.rb"
require_relative "../lib/code/code_generation.rb"

describe "ir" do
    it "generates llvm" do
        data = {
"int foo;" => "@foo = global i32 zeroinitializer\n",
"char foo;" => "@foo = global i8 zeroinitializer\n",
"int foo[42];" => "@foo = global [42 x i32] zeroinitializer\n",
"char foo[42];" => "@foo = global [42 x i8] zeroinitializer\n",
#-------------------------------------------------------------------
"int main(void) { return 0; }" =>
"
define i32 @main() {
    ret i32 0
}",
#-------------------------------------------------------------------
"int main(int foo) { return foo; }" =>
"
define i32 @main(i32 %foo) {
    %1 = alloca i32
    store i32 %foo, i32* %1
    %2 = load i32* %1
    ret i32 %2
}",
#-------------------------------------------------------------------
"int foo; int main(void) { return foo; }" =>
"@foo = global i32 zeroinitializer

define i32 @main() {
    %1 = load i32* @foo
    ret i32 %1
}",
#-------------------------------------------------------------------
"int foo; int main(void) { foo = 42; return foo; }" =>
"@foo = global i32 zeroinitializer

define i32 @main() {
    store i32 42, i32* @foo
    %1 = load i32* @foo
    ret i32 %1
}",
#-------------------------------------------------------------------
"int main(void) { int foo; foo = 42; return foo; }" =>
"
define i32 @main() {
    %foo = alloca i32
    store i32 42, i32* %foo
    %1 = load i32* %foo
    ret i32 %1
}",
#-------------------------------------------------------------------
"int main(void) { int foo[4]; foo[3] = 42; return foo[3]; }" =>
"
define i32 @main() {
    %foo = alloca [4 x i32]
    %1 = getelementptr inbounds [4 x i32]* %foo, i32 0, i32 3
    store i32 42, i32* %1
    %2 = getelementptr inbounds [4 x i32]* %foo, i32 0, i32 3
    %3 = load i32* %2
    ret i32 %3
}",
#-------------------------------------------------------------------
"int foo[4]; int main(void) { foo[3] = 42; return foo[3]; }" =>
"@foo = global [4 x i32] zeroinitializer

define i32 @main() {
    %1 = getelementptr inbounds [4 x i32]* @foo, i32 0, i32 3
    store i32 42, i32* %1
    %2 = getelementptr inbounds [4 x i32]* @foo, i32 0, i32 3
    %3 = load i32* %2
    ret i32 %3
}",
#-------------------------------------------------------------------
"int main(void) { int i; i = 0; if (i) { i = 42; } return i; }" =>
"
define i32 @main() {
    %i = alloca i32
    store i32 0, i32* %i
    %1 = load i32* %i
    %2 = icmp ne i32 %1, 0
    br i1 %2, label %if_then1, label %if_end2
  if_then1:
    store i32 42, i32* %i
    br label %if_end2
  if_end2:
    %3 = load i32* %i
    ret i32 %3
}",
#-------------------------------------------------------------------
"int main(void) { int i; i = 0; if (i) { i = 42; } else { i = 2; } return i; }" =>
"
define i32 @main() {
    %i = alloca i32
    store i32 0, i32* %i
    %1 = load i32* %i
    %2 = icmp ne i32 %1, 0
    br i1 %2, label %if_then1, label %if_else2
  if_then1:
    store i32 42, i32* %i
    br label %if_end3
  if_else2:
    store i32 2, i32* %i
    br label %if_end3
  if_end3:
    %3 = load i32* %i
    ret i32 %3
}",
#-------------------------------------------------------------------
"int main(void) { int i; i = 0; if (i) { i = 1; } else if (3) { i = 2; } else { i = 3; } return i; }" =>
"
define i32 @main() {
    %i = alloca i32
    store i32 0, i32* %i
    %1 = load i32* %i
    %2 = icmp ne i32 %1, 0
    br i1 %2, label %if_then1, label %if_else2
  if_then1:
    store i32 1, i32* %i
    br label %if_end3
  if_else2:
    %3 = icmp ne i32 3, 0
    br i1 %3, label %if_then4, label %if_else5
  if_then4:
    store i32 2, i32* %i
    br label %if_end6
  if_else5:
    store i32 3, i32* %i
    br label %if_end6
  if_end6:
    br label %if_end3
  if_end3:
    %4 = load i32* %i
    ret i32 %4
}",
#-------------------------------------------------------------------
"int main(void) { int i; i = 1; while (i) { i = 0; } return i; }" =>
"
define i32 @main() {
    %i = alloca i32
    store i32 1, i32* %i
    br label %while_start1
  while_start1:
    %1 = load i32* %i
    %2 = icmp ne i32 %1, 0
    br i1 %2, label %while_body2, label %while_end3
  while_body2:
    store i32 0, i32* %i
    br label %while_start1
  while_end3:
    %3 = load i32* %i
    ret i32 %3
}",
#-------------------------------------------------------------------
uc_operator_program("+") => llvm_operator_program("add"),
uc_operator_program("-") => llvm_operator_program("sub"),
uc_operator_program("*") => llvm_operator_program("mul"),
uc_operator_program("/") => llvm_operator_program("div"),
uc_operator_program("==") => llvm_boolean_program("eq"),
uc_operator_program("!=") => llvm_boolean_program("ne"),
uc_operator_program("<") => llvm_boolean_program("slt"),
uc_operator_program(">") => llvm_boolean_program("sgt"),
uc_operator_program("<=") => llvm_boolean_program("sle"),
uc_operator_program(">=") => llvm_boolean_program("sge"),
uc_operator_program("&&") =>
"
define i32 @main() {
    %1 = icmp ne i32 40, 0
    %2 = icmp ne i32 2, 0
    %3 = and i1 %1, %2
    %4 = zext i1 %3 to i32
    ret i32 %4
}",
uc_operator_program("||") =>
"
define i32 @main() {
    %1 = or i32 40, 2
    %2 = icmp ne i32 %1, 0
    %3 = zext i1 %2 to i32
    ret i32 %3
}",
#-------------------------------------------------------------------
"int main(void) { return 1 < 2 && 4 > 5; }" =>
"
define i32 @main() {
    %1 = icmp slt i32 1, 2
    %2 = zext i1 %1 to i32
    %3 = icmp sgt i32 4, 5
    %4 = zext i1 %3 to i32
    %5 = icmp ne i32 %2, 0
    %6 = icmp ne i32 %4, 0
    %7 = and i1 %5, %6
    %8 = zext i1 %7 to i32
    ret i32 %8
}",
#-------------------------------------------------------------------
"int main(void) { return 1 < 2 && 4 > 5 || 42; }" =>
"
define i32 @main() {
    %1 = icmp slt i32 1, 2
    %2 = zext i1 %1 to i32
    %3 = icmp sgt i32 4, 5
    %4 = zext i1 %3 to i32
    %5 = icmp ne i32 %2, 0
    %6 = icmp ne i32 %4, 0
    %7 = and i1 %5, %6
    %8 = zext i1 %7 to i32
    %9 = or i32 %8, 42
    %10 = icmp ne i32 %9, 0
    %11 = zext i1 %10 to i32
    ret i32 %11
}",
#-------------------------------------------------------------------
"int foo(void) { return 42; } int main(void) { return foo(); }" =>
"
define i32 @foo() {
    ret i32 42
}
define i32 @main() {
    %1 = call i32 @foo ()
    ret i32 %1
}",
#-------------------------------------------------------------------
"int foo(int n) { return n; } int main(void) { return foo(42); }" =>
"
define i32 @foo(i32 %n) {
    %1 = alloca i32
    store i32 %n, i32* %1
    %2 = load i32* %1
    ret i32 %2
}
define i32 @main() {
    %1 = call i32 @foo (i32 42)
    ret i32 %1
}",
#-------------------------------------------------------------------
"int foo(int n, char c) { return n + (int)c; } int main(void) { return foo(3, 'a'); }" =>
"
define i32 @foo(i32 %n, i8 %c) {
    %1 = alloca i32
    store i32 %n, i32* %1
    %2 = alloca i8
    store i8 %c, i8* %2
    %3 = load i32* %1
    %4 = load i8* %2
    %5 = sext i8 %4 to i32
    %6 = add i32 %3, %5
    ret i32 %6
}
define i32 @main() {
    %1 = call i32 @foo (i32 3, i8 97)
    ret i32 %1
}",
#-------------------------------------------------------------------
"int fib(int n) { if (n < 2) { return n; } return fib(n-1) + fib(n-2); } int main(void) { return fib(10); }" =>
"
define i32 @fib(i32 %n) {
    %1 = alloca i32
    store i32 %n, i32* %1
    %2 = load i32* %1
    %3 = icmp slt i32 %2, 2
    %4 = zext i1 %3 to i32
    %5 = icmp ne i32 %4, 0
    br i1 %5, label %if_then1, label %if_end2
  if_then1:
    %6 = load i32* %1
    ret i32 %6
    br label %if_end2
  if_end2:
    %8 = load i32* %1
    %9 = sub i32 %8, 1
    %10 = call i32 @fib (i32 %9)
    %11 = load i32* %1
    %12 = sub i32 %11, 2
    %13 = call i32 @fib (i32 %12)
    %14 = add i32 %10, %13
    ret i32 %14
}
define i32 @main() {
    %1 = call i32 @fib (i32 10)
    ret i32 %1
}",
#-------------------------------------------------------------------
"int not(int n) { return !n; } int main(void) { return not(0); }" =>
"
define i32 @not(i32 %n) {
    %1 = alloca i32
    store i32 %n, i32* %1
    %2 = load i32* %1
    %3 = icmp eq i32 %2, 0
    %4 = zext i1 %3 to i32
    ret i32 %4
}
define i32 @main() {
    %1 = call i32 @not (i32 0)
    ret i32 %1
}",
#-------------------------------------------------------------------
"void meh(int n) { !n; } int main(void) { meh(0); return 0; }" =>
"
define void @meh(i32 %n) {
    %1 = alloca i32
    store i32 %n, i32* %1
    %2 = load i32* %1
    %3 = icmp eq i32 %2, 0
    %4 = zext i1 %3 to i32
    ret void
}
define i32 @main() {
    call void @meh (i32 0)
    ret i32 0
}",
#-------------------------------------------------------------------
"int negate(int n) { return -n; } int main(void) { return negate(1); }" =>
"
define i32 @negate(i32 %n) {
    %1 = alloca i32
    store i32 %n, i32* %1
    %2 = load i32* %1
    %3 = sub i32 0, %2
    ret i32 %3
}
define i32 @main() {
    %1 = call i32 @negate (i32 1)
    ret i32 %1
}",
        }
        data.each do |uc, llvm|
            expect(uc_to_llvm(uc)).to eq llvm
        end
    end

    def uc_to_llvm string
        ast = Parser.new.parse string
        if semantic_analysis(ast)
            ir = generate_ir ast
            return generate_llvm ir
        end
    end
    def uc_operator_program(op)
        "int main(void) { return 40 #{op} 2; }"
    end
    def llvm_operator_program(op)
        "\ndefine i32 @main() {\n    %1 = #{op} i32 40, 2\n    ret i32 %1\n}"
    end
    def llvm_boolean_program(op)
"
define i32 @main() {
    %1 = icmp #{op} i32 40, 2
    %2 = zext i1 %1 to i32
    ret i32 %2
}"
    end
end
