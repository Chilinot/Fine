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
uc_operator_program("/") => llvm_operator_program("sdiv"),
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
#-------------------------------------------------------------------
"int first(int array[]) { return array[0]; } int main(void) { int things[10]; things[0] = 42; return first(things); }" =>
"
define i32 @first(i32* %array) {
    %1 = getelementptr inbounds i32* %array, i32 0
    %2 = load i32* %1
    ret i32 %2
}
define i32 @main() {
    %things = alloca [10 x i32]
    %1 = getelementptr inbounds [10 x i32]* %things, i32 0, i32 0
    store i32 42, i32* %1
    %2 = getelementptr inbounds [10 x i32]* %things, i32 0, i32 0
    %3 = call i32 @first (i32* %2)
    ret i32 %3
}",
#-------------------------------------------------------------------
"int second(int a[]) { return a[1]; } int main(void) { int things[10]; things[0] = 42; return second(things); }" =>
"
define i32 @second(i32* %a) {
    %1 = getelementptr inbounds i32* %a, i32 1
    %2 = load i32* %1
    ret i32 %2
}
define i32 @main() {
    %things = alloca [10 x i32]
    %1 = getelementptr inbounds [10 x i32]* %things, i32 0, i32 0
    store i32 42, i32* %1
    %2 = getelementptr inbounds [10 x i32]* %things, i32 0, i32 0
    %3 = call i32 @second (i32* %2)
    ret i32 %3
}",
#-------------------------------------------------------------------
"int main(void) { char c; c = 'c'; return (int)c; }" =>
"
define i32 @main() {
    %c = alloca i8
    store i8 99, i8* %c
    %1 = load i8* %c
    %2 = sext i8 %1 to i32
    ret i32 %2
}",
#-------------------------------------------------------------------
"char main(void) { int i; i = 99; return (char)i; }" =>
"
define i8 @main() {
    %i = alloca i32
    store i32 99, i32* %i
    %1 = load i32* %i
    %2 = trunc i32 %1 to i8
    ret i8 %2
}",
#-------------------------------------------------------------------
"char main(void) { int i; i = 99; return (char)(int)(char)i; }" =>
"
define i8 @main() {
    %i = alloca i32
    store i32 99, i32* %i
    %1 = load i32* %i
    %2 = trunc i32 %1 to i8
    %3 = sext i8 %2 to i32
    %4 = trunc i32 %3 to i8
    ret i8 %4
}",
#-------------------------------------------------------------------
"void putint(int n); int main(void) { putint(42); return 10; }" =>
'%struct._IO_FILE = type { i32, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, %struct._IO_marker*, %struct._IO_FILE*, i32, i32, i64, i16, i8, [1 x i8], i8*, i64, i8*, i8*, i8*, i8*, i64, i32, [20 x i8] }
%struct._IO_marker = type { %struct._IO_marker*, %struct._IO_FILE*, i32 }

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1
@stdout = external global %struct._IO_FILE*
@.str1 = private unnamed_addr constant [3 x i8] c"%s\00", align 1

declare i32 @printf(i8*, ...)
declare i32 @fputs(i8*, %struct._IO_FILE*)
declare i32 @__isoc99_scanf(i8*, ...)

define void @putint(i32 %x) {
    %1 = alloca i32, align 4
    store i32 %x, i32* %1, align 4
    %2 = load i32* %1, align 4
    %3 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([3 x i8]* @.str, i32 0, i32 0), i32 %2)
    ret void
}

define i32 @main() {
    call void @putint (i32 42)
    ret i32 10
}',
#-------------------------------------------------------------------
"void putstring(char s[]); int main(void) { return 10; }" =>
'%struct._IO_FILE = type { i32, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, %struct._IO_marker*, %struct._IO_FILE*, i32, i32, i64, i16, i8, [1 x i8], i8*, i64, i8*, i8*, i8*, i8*, i64, i32, [20 x i8] }
%struct._IO_marker = type { %struct._IO_marker*, %struct._IO_FILE*, i32 }

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1
@stdout = external global %struct._IO_FILE*
@.str1 = private unnamed_addr constant [3 x i8] c"%s\00", align 1

declare i32 @printf(i8*, ...)
declare i32 @fputs(i8*, %struct._IO_FILE*)
declare i32 @__isoc99_scanf(i8*, ...)

define void @putstring(i8* %s) {
    %1 = alloca i8*, align 8
    store i8* %s, i8** %1, align 8
    %2 = load i8** %1, align 8
    %3 = load %struct._IO_FILE** @stdout, align 8
    %4 = call i32 @fputs(i8* %2, %struct._IO_FILE* %3)
    ret void
}

define i32 @main() {
    ret i32 10
}',
#-------------------------------------------------------------------
"int getint(void); int main(void) { return 10; }" =>
'%struct._IO_FILE = type { i32, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, %struct._IO_marker*, %struct._IO_FILE*, i32, i32, i64, i16, i8, [1 x i8], i8*, i64, i8*, i8*, i8*, i8*, i64, i32, [20 x i8] }
%struct._IO_marker = type { %struct._IO_marker*, %struct._IO_FILE*, i32 }

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1
@stdout = external global %struct._IO_FILE*
@.str1 = private unnamed_addr constant [3 x i8] c"%s\00", align 1

declare i32 @printf(i8*, ...)
declare i32 @fputs(i8*, %struct._IO_FILE*)
declare i32 @__isoc99_scanf(i8*, ...)

define i32 @getint() {
    %i = alloca i32, align 4
    %1 = call i32 (i8*, ...)* @__isoc99_scanf(i8* getelementptr inbounds ([3 x i8]* @.str, i32 0, i32 0), i32* %i)
    %2 = load i32* %i, align 4
    ret i32 %2
}

define i32 @main() {
    ret i32 10
}',
#-------------------------------------------------------------------
"int getstring(char s[]); int main(void) { return 10; }" =>
'%struct._IO_FILE = type { i32, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, %struct._IO_marker*, %struct._IO_FILE*, i32, i32, i64, i16, i8, [1 x i8], i8*, i64, i8*, i8*, i8*, i8*, i64, i32, [20 x i8] }
%struct._IO_marker = type { %struct._IO_marker*, %struct._IO_FILE*, i32 }

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1
@stdout = external global %struct._IO_FILE*
@.str1 = private unnamed_addr constant [3 x i8] c"%s\00", align 1

declare i32 @printf(i8*, ...)
declare i32 @fputs(i8*, %struct._IO_FILE*)
declare i32 @__isoc99_scanf(i8*, ...)

define i32 @getstring(i8* %s) {
    %1 = alloca i8*, align 8
    store i8* %s, i8** %1, align 8
    %2 = load i8** %1, align 8
    %3 = call i32 (i8*, ...)* @__isoc99_scanf(i8* getelementptr inbounds ([3 x i8]* @.str1, i32 0, i32 0), i8* %2)
    ret i32 %3
}

define i32 @main() {
    ret i32 10
}',
"/* Fibbonacci, in the simple and naive form */
/* Prints fibbonacci numbers for n=1..12 */

void putint(int n);
void putstring(char s[]);

int fib(int n) {
  if (n < 2) { return n; }
  return fib(n-1) + fib(n-2);
}

int main (void) {
  int i;
  char space[2];
  char cr[2];
  space[0] = ' ';  space[1] = (char)0;
  cr[0]    = '\n'; cr[1]    = (char)0;


  i = 0;

  while (i<=12) {
    putint(i);
    putstring(space);
    putint(fib(i));
    putstring(cr);
    i = i + 1;
  }
  return 0;
}" =>
'%struct._IO_FILE = type { i32, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, %struct._IO_marker*, %struct._IO_FILE*, i32, i32, i64, i16, i8, [1 x i8], i8*, i64, i8*, i8*, i8*, i8*, i64, i32, [20 x i8] }
%struct._IO_marker = type { %struct._IO_marker*, %struct._IO_FILE*, i32 }

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1
@stdout = external global %struct._IO_FILE*
@.str1 = private unnamed_addr constant [3 x i8] c"%s\00", align 1

declare i32 @printf(i8*, ...)
declare i32 @fputs(i8*, %struct._IO_FILE*)
declare i32 @__isoc99_scanf(i8*, ...)

define void @putint(i32 %x) {
    %1 = alloca i32, align 4
    store i32 %x, i32* %1, align 4
    %2 = load i32* %1, align 4
    %3 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([3 x i8]* @.str, i32 0, i32 0), i32 %2)
    ret void
}

define void @putstring(i8* %s) {
    %1 = alloca i8*, align 8
    store i8* %s, i8** %1, align 8
    %2 = load i8** %1, align 8
    %3 = load %struct._IO_FILE** @stdout, align 8
    %4 = call i32 @fputs(i8* %2, %struct._IO_FILE* %3)
    ret void
}

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
    %i = alloca i32
    %space = alloca [2 x i8]
    %cr = alloca [2 x i8]
    %1 = getelementptr inbounds [2 x i8]* %space, i32 0, i32 0
    store i8 32, i8* %1
    %2 = getelementptr inbounds [2 x i8]* %space, i32 0, i32 1
    %3 = trunc i32 0 to i8
    store i8 %3, i8* %2
    %4 = getelementptr inbounds [2 x i8]* %cr, i32 0, i32 0
    store i8 10, i8* %4
    %5 = getelementptr inbounds [2 x i8]* %cr, i32 0, i32 1
    %6 = trunc i32 0 to i8
    store i8 %6, i8* %5
    store i32 0, i32* %i
    br label %while_start1
  while_start1:
    %7 = load i32* %i
    %8 = icmp sle i32 %7, 12
    %9 = zext i1 %8 to i32
    %10 = icmp ne i32 %9, 0
    br i1 %10, label %while_body2, label %while_end3
  while_body2:
    %11 = load i32* %i
    call void @putint (i32 %11)
    %12 = getelementptr inbounds [2 x i8]* %space, i32 0, i32 0
    call void @putstring (i8* %12)
    %13 = load i32* %i
    %14 = call i32 @fib (i32 %13)
    call void @putint (i32 %14)
    %15 = getelementptr inbounds [2 x i8]* %cr, i32 0, i32 0
    call void @putstring (i8* %15)
    %16 = load i32* %i
    %17 = add i32 %16, 1
    store i32 %17, i32* %i
    br label %while_start1
  while_end3:
    ret i32 0
}',
"// This program illustrates the bubblesort algorithm by sorting an
// array of char and printing the intermediate states of the array.


void putstring(char s[]);

char eol[2];
int n;


void bubble(char a[]) {
  int i;
  int j;
  char t;

  putstring (a);
  putstring (eol);
  i=n-1;
  while (i>0) {
    j = 0;
    while (j<i) {
      if (a[j] > a[j+1]) {
	  t = a[j];
	  a[j] = a[j+1];
	  a[j+1] = t;
	}
      j = j + 1;
    }
    putstring (a);
    putstring (eol);
    i = i -1;
  }
}

int main(void)
{
  char s[27];
  int i;
  char t;
  int q;

  eol[0] = '\n';
  eol[1] = (char)0;

  n = 26;

  s[n] = (char)0;

  // Fill the string with a permutation of the characters a-z
  i = 0;
  q = 11;
  while (i<n) {
    t = (char)(q - (q / 26)*26); // q mod 26
    s[i] = 'a'+t;
    i = i + 1;
    q = q + 17;
  }

  bubble(s);
  return 0;
}
" =>
'%struct._IO_FILE = type { i32, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, %struct._IO_marker*, %struct._IO_FILE*, i32, i32, i64, i16, i8, [1 x i8], i8*, i64, i8*, i8*, i8*, i8*, i64, i32, [20 x i8] }
%struct._IO_marker = type { %struct._IO_marker*, %struct._IO_FILE*, i32 }

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1
@stdout = external global %struct._IO_FILE*
@.str1 = private unnamed_addr constant [3 x i8] c"%s\00", align 1

declare i32 @printf(i8*, ...)
declare i32 @fputs(i8*, %struct._IO_FILE*)
declare i32 @__isoc99_scanf(i8*, ...)

define void @putstring(i8* %s) {
    %1 = alloca i8*, align 8
    store i8* %s, i8** %1, align 8
    %2 = load i8** %1, align 8
    %3 = load %struct._IO_FILE** @stdout, align 8
    %4 = call i32 @fputs(i8* %2, %struct._IO_FILE* %3)
    ret void
}
@eol = global [2 x i8] zeroinitializer
@n = global i32 zeroinitializer

define void @bubble(i8* %a) {
    %i = alloca i32
    %j = alloca i32
    %t = alloca i8
    %1 = getelementptr inbounds i8* %a, i32 0
    call void @putstring (i8* %1)
    %2 = getelementptr inbounds [2 x i8]* @eol, i32 0, i32 0
    call void @putstring (i8* %2)
    %3 = load i32* @n
    %4 = sub i32 %3, 1
    store i32 %4, i32* %i
    br label %while_start1
  while_start1:
    %5 = load i32* %i
    %6 = icmp sgt i32 %5, 0
    %7 = zext i1 %6 to i32
    %8 = icmp ne i32 %7, 0
    br i1 %8, label %while_body2, label %while_end3
  while_body2:
    store i32 0, i32* %j
    br label %while_start4
  while_start4:
    %9 = load i32* %j
    %10 = load i32* %i
    %11 = icmp slt i32 %9, %10
    %12 = zext i1 %11 to i32
    %13 = icmp ne i32 %12, 0
    br i1 %13, label %while_body5, label %while_end6
  while_body5:
    %14 = load i32* %j
    %15 = getelementptr inbounds i8* %a, i32 %14
    %16 = load i8* %15
    %17 = load i32* %j
    %18 = add i32 %17, 1
    %19 = getelementptr inbounds i8* %a, i32 %18
    %20 = load i8* %19
    %21 = icmp sgt i8 %16, %20
    %22 = zext i1 %21 to i8
    %23 = icmp ne i8 %22, 0
    br i1 %23, label %if_then7, label %if_end8
  if_then7:
    %24 = load i32* %j
    %25 = getelementptr inbounds i8* %a, i32 %24
    %26 = load i8* %25
    store i8 %26, i8* %t
    %27 = load i32* %j
    %28 = getelementptr inbounds i8* %a, i32 %27
    %29 = load i32* %j
    %30 = add i32 %29, 1
    %31 = getelementptr inbounds i8* %a, i32 %30
    %32 = load i8* %31
    store i8 %32, i8* %28
    %33 = load i32* %j
    %34 = add i32 %33, 1
    %35 = getelementptr inbounds i8* %a, i32 %34
    %36 = load i8* %t
    store i8 %36, i8* %35
    br label %if_end8
  if_end8:
    %37 = load i32* %j
    %38 = add i32 %37, 1
    store i32 %38, i32* %j
    br label %while_start4
  while_end6:
    %39 = getelementptr inbounds i8* %a, i32 0
    call void @putstring (i8* %39)
    %40 = getelementptr inbounds [2 x i8]* @eol, i32 0, i32 0
    call void @putstring (i8* %40)
    %41 = load i32* %i
    %42 = sub i32 %41, 1
    store i32 %42, i32* %i
    br label %while_start1
  while_end3:
    ret void
}
define i32 @main() {
    %s = alloca [27 x i8]
    %i = alloca i32
    %t = alloca i8
    %q = alloca i32
    %1 = getelementptr inbounds [2 x i8]* @eol, i32 0, i32 0
    store i8 10, i8* %1
    %2 = getelementptr inbounds [2 x i8]* @eol, i32 0, i32 1
    %3 = trunc i32 0 to i8
    store i8 %3, i8* %2
    store i32 26, i32* @n
    %4 = load i32* @n
    %5 = getelementptr inbounds [27 x i8]* %s, i32 0, i32 %4
    %6 = trunc i32 0 to i8
    store i8 %6, i8* %5
    store i32 0, i32* %i
    store i32 11, i32* %q
    br label %while_start1
  while_start1:
    %7 = load i32* %i
    %8 = load i32* @n
    %9 = icmp slt i32 %7, %8
    %10 = zext i1 %9 to i32
    %11 = icmp ne i32 %10, 0
    br i1 %11, label %while_body2, label %while_end3
  while_body2:
    %12 = load i32* %q
    %13 = load i32* %q
    %14 = sdiv i32 %13, 26
    %15 = mul i32 %14, 26
    %16 = sub i32 %12, %15
    %17 = trunc i32 %16 to i8
    store i8 %17, i8* %t
    %18 = load i32* %i
    %19 = getelementptr inbounds [27 x i8]* %s, i32 0, i32 %18
    %20 = load i8* %t
    %21 = add i8 97, %20
    store i8 %21, i8* %19
    %22 = load i32* %i
    %23 = add i32 %22, 1
    store i32 %23, i32* %i
    %24 = load i32* %q
    %25 = add i32 %24, 17
    store i32 %25, i32* %q
    br label %while_start1
  while_end3:
    %26 = getelementptr inbounds [27 x i8]* %s, i32 0, i32 0
    call void @bubble (i8* %26)
    ret i32 0
}'
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
