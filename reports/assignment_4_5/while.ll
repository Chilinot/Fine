
define i32 @main() {
    %i = alloca i32
    br label %while_start1
  while_start1:
    %1 = load i32* %i
    %2 = icmp ne i32 %1, 0
    br i1 %2, label %while_body2, label %while_end3
  while_body2:
    store i32 42, i32* %i
    br label %while_start1
  while_end3:
    ret i32 0
}