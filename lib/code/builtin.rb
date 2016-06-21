
class Builtin
    attr_reader :ir
    def initialize
        @builtin = []
    end
    def include_builtin name
        @builtin << name
    end
    def has_header?
        not @builtin.empty?
    end
    def is_built_in? function
        builtin_functions = [
            ExternFunctionDeclarationNode.new(:VOID, "putint", [VariableDeclarationNode.new(:INT, "n")]),
            ExternFunctionDeclarationNode.new(:VOID, "putstring", [ArrayDeclarationNode.new(:CHAR, "s")]),
            ExternFunctionDeclarationNode.new(:INT, "getint", []),
            ExternFunctionDeclarationNode.new(:INT, "getstring", [ArrayDeclarationNode.new(:CHAR, "s")]),
        ]
        builtin_functions.any? do |f|
            f.type == function.type and
            f.name == function.name and
            f.formals.count == function.formals.count and
            (function.formals.count == 0 or (f.formals[0].type == function.formals[0].type))
        end
    end
    def generate_llvm formal_map = nil
header = '%struct._IO_FILE = type { i32, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, i8*, %struct._IO_marker*, %struct._IO_FILE*, i32, i32, i64, i16, i8, [1 x i8], i8*, i64, i8*, i8*, i8*, i8*, i64, i32, [20 x i8] }
%struct._IO_marker = type { %struct._IO_marker*, %struct._IO_FILE*, i32 }

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1
@stdout = external global %struct._IO_FILE*
@.str1 = private unnamed_addr constant [3 x i8] c"%s\00", align 1

declare i32 @printf(i8*, ...)
declare i32 @fputs(i8*, %struct._IO_FILE*)
declare i32 @__isoc99_scanf(i8*, ...)
'

putint = '
define void @putint(i32 %x) {
    %1 = alloca i32, align 4
    store i32 %x, i32* %1, align 4
    %2 = load i32* %1, align 4
    %3 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([3 x i8]* @.str, i32 0, i32 0), i32 %2)
    ret void
}
'

putstring = '
define void @putstring(i8* %s) {
    %1 = alloca i8*, align 8
    store i8* %s, i8** %1, align 8
    %2 = load i8** %1, align 8
    %3 = load %struct._IO_FILE** @stdout, align 8
    %4 = call i32 @fputs(i8* %2, %struct._IO_FILE* %3)
    ret void
}
'

getint = '
define i32 @getint() {
    %i = alloca i32, align 4
    %1 = call i32 (i8*, ...)* @__isoc99_scanf(i8* getelementptr inbounds ([3 x i8]* @.str, i32 0, i32 0), i32* %i)
    %2 = load i32* %i, align 4
    ret i32 %2
}
'

getstring = '
define i32 @getstring(i8* %s) {
    %1 = alloca i8*, align 8
    store i8* %s, i8** %1, align 8
    %2 = load i8** %1, align 8
    %3 = call i32 (i8*, ...)* @__isoc99_scanf(i8* getelementptr inbounds ([3 x i8]* @.str1, i32 0, i32 0), i8* %2)
    ret i32 %3
}
'
        llvm = ""
        llvm += header unless @builtin.empty?
        llvm += putint if @builtin.include? "putint"
        llvm += putstring if @builtin.include? "putstring"
        llvm += getint if @builtin.include? "getint"
        llvm += getstring if @builtin.include? "getstring"
        return llvm
    end
end
