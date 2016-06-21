define i32 @foo() {
    %scalar = alloca i32       ; int scalar;
    %array = alloca [10 x i32] ; int array[10];

    ; array[0] = 42;
    %1 = getelementptr inbounds [10 x i32]* %array, i32 0, i32 0
    store i32 42, i32* %1

    ; scalar = 43;
    store i32 43, i32* %scalar

    ; return array[1];
    %2 = getelementptr inbounds [10 x i32]* %array, i32 0, i32 1
    %3 = load i32* %2
    ret i32 %3
}