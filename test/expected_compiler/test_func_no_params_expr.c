#include <stdio.h>

float pi();
float zero();

float pi() {
    return 3.14;
}

float zero() {
    return 0.0;
}

int main() {
    float r;
    r = (pi() + 1.0);
    printf("%f\n", r);
    r = (pi() * 2.0);
    printf("%f\n", r);
    printf("%f\n", zero());
    return 0;
}
