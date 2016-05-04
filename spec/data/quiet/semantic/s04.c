int foo(char x[]) {
  return (int)x[0];
}

void main(void) {
  char a[10];
  foo(a);
}
