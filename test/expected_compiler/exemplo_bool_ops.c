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
    if ((a && (1 || 0))) {
        printf("%f\n", 1.0);
    }
    return 0;
}
