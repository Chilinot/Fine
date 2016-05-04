int foo(char a) {
    return (int)a;
}

void main(void) {
    char a;
    int b;
    a = (char)((int)a + b);
    a = (char)(4 + foo('a') + 12);
}
