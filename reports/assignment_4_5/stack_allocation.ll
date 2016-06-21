define i32 @foo() {
  %foobar = alloca i32      ; int foobar;
  store i32 1, i32* %foobar ; foobar = 1;
  %1 = load i32* %foobar    ;
  ret i32 %1                ; return foobar;
}
