#include <stdio.h>

int main() {
    int a;
    int b;
    int c;
    a = 1;
    b = 0;
    c = (a && b);
    printf("%f\n", c);
    c = (a || b);
    printf("%f\n", c);
    c = (a && a);
    printf("%f\n", c);
    c = (b || b);
    printf("%f\n", c);
    return 0;
}
