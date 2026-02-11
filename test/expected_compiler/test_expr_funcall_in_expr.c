#include <stdio.h>

float dobro(float x);
float soma(float a, float b);

float dobro(float x) {
    return (x * 2.0);
}

float soma(float a, float b) {
    return (a + b);
}

int main() {
    float r;
    r = (dobro(3.0) + 1.0);
    printf("%f\n", r);
    r = soma(dobro(2.0), 5.0);
    printf("%f\n", r);
    r = dobro(soma(1.0, 2.0));
    printf("%f\n", r);
    return 0;
}
