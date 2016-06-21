define i32 @main() {
    %i = alloca i32
    store i32 10, i32* %i
    br label %while_start1
  while_start1:
    %1 = load i32* %i
    %2 = icmp sgt i32 %1, 0
    %3 = zext i1 %2 to i32
    %4 = icmp ne i32 %3, 0
    br i1 %4, label %while_body2, label %while_end3
  while_body2:
    %5 = load i32* %i
    %6 = add i32 %5, 1
    store i32 %6, i32* %i
    br label %while_start1
  while_end3:
    ret i32 0
}
