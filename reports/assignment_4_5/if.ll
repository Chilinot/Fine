define i32 @main() {
    %i = alloca i32
    %1 = icmp ne i32 0, 0
    br i1 %1, label %if_then1, label %if_else2
  if_then1:
    store i32 1, i32* %i
    br label %if_end3
  if_else2:
    %2 = icmp ne i32 1, 0
    br i1 %2, label %if_then4, label %if_else5
  if_then4:
    store i32 2, i32* %i
    br label %if_end6
  if_else5:
    store i32 3, i32* %i
    br label %if_end6
  if_end6:
    br label %if_end3
  if_end3:
    ret i32 0
}
