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
"int main(void) { return 40 + 2; }" =>
"
define i32 @main() {
    %1 = add i32 40, 2
    ret i32 %1
}"


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
end
