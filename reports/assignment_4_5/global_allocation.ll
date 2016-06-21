@foobar = global i32 zeroinitializer ; int i;

define i32 @foo() {
  store i32 1, i32* @foobar ; foobar = 1;
  %1 = load i32* @foobar    ;
  ret i32 %1                ; return foobar;
}
