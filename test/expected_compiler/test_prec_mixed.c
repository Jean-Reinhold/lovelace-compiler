#include <stdio.h>

int main() {
    float a;
    float b;
    int r;
    a = 10.0;
    b = 5.0;
    r = (((a + b) > 10.0) && ((a * b) > 40.0));
    printf("%f\n", r);
    r = (((a - b) < 10.0) || ((a / b) == 2.0));
    printf("%f\n", r);
    return 0;
}
