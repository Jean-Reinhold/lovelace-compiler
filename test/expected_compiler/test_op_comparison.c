#include <stdio.h>

int main() {
    float a;
    float b;
    a = 5.0;
    b = 10.0;
    if ((a < b)) {
        printf("%f\n", 1.0);
    }
    if ((b > a)) {
        printf("%f\n", 2.0);
    }
    if ((a == a)) {
        printf("%f\n", 3.0);
    }
    return 0;
}
