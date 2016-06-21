define i32 @main() {
    %i = alloca i32
    %1 = icmp ne i32 0, 0                         ; compute condition
    br i1 %1, label %if_then1, label %if_else2    ; initial if branch
  if_then1:                                       ; then block
    store i32 1, i32* %i
    br label %if_end3
  if_else2:                                       ; else block
    %2 = icmp ne i32 1, 0                         ; compute else if condition
    br i1 %2, label %if_then4, label %if_else5    ; else if branch
  if_then4:                                       ; else if block
    store i32 2, i32* %i
    br label %if_end6
  if_else5:                                       ; final else block
    store i32 3, i32* %i
    br label %if_end6
  if_end6:                                        ; inner end label
    br label %if_end3
  if_end3:                                        ; outer end label
    ret i32 0
}
